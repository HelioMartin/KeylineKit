# LayerPreview

`#LayerPreview` muestra una vista SwiftUI junto con un inspector de capas. La
macro analiza la closure con SwiftSyntax al compilar y conserva el preview de
produccion sin modificaciones.

Agrega este paquete como dependencia e importa el modulo en tu target de UI:

```swift
import LayerPreview
import SwiftUI

#Preview("Profile layers") {
    #LayerPreview {
        VStack {
            ProfileView()
        }
        .padding(24)
    }
}
```

Por defecto, `#LayerPreview` muestra todas las anotaciones sin configuración adicional.
Si se quieren filtrar, se puede pasar un array explícito:

```swift
#Preview("Profile padding") {
    #LayerPreview(.layers, .padding) {
        ProfileView()
    }
}
```

Los valores posibles de `LayerPreviewAnnotation` son:

- `.none`: oculta todas las etiquetas.
- `.layers`: muestra los recuadros y nombres de las capas.
- `.padding`: muestra los valores de padding en los lados que afectan.
- `.spacing`: muestra las separaciones entre los elementos de stacks.

Los valores se pueden combinar pasándolos como argumentos separados, por ejemplo
`.layers, .padding`.

Las lineas amarillas que delimitan los contenedores estan activadas por defecto.
Se pueden desactivar explicitamente:

```swift
#LayerPreview(.layers, showContainerLines: false) {
    MyView()
}
```

El Canvas muestra cada nodo con su propio borde naranja y una etiqueta con su
nombre en la esquina superior izquierda. El padding declarado ya no se muestra
como texto combinado: aparece como una flecha con el valor, pegada al borde
exacto que afecta:

- `↑ valor` sobre el borde superior (`.top` o `.vertical`).
- `↓ valor` sobre el borde inferior (`.bottom` o `.vertical`).
- `← valor` sobre el borde izquierdo (`.leading` o `.horizontal`).
- `→ valor` sobre el borde derecho (`.trailing` o `.horizontal`).

Por ejemplo, `.padding(24)` marca los cuatro bordes con `24`, mientras que
`.padding(.horizontal, 16)` solo marca `←16` y `→16`. Si hay varias llamadas a
`.padding(...)` encadenadas, la ultima que afecte a un borde es la que se
muestra en ese borde.

La instrumentación recorre la closure de cualquier inicializador con nombre
capitalizado (`Grid`, `Form`, `ScrollView`, `NavigationStack`, una vista propia
como `CustomCard`, etc.), sin necesidad de listar cada contenedor. Solo se
excluye una lista breve de controles cuya closure final es una accion, no
contenido (`Button`), para que `Button("Guardar") { guardar() }` nunca se
reescriba por dentro.

Ademas, entre cada par de elementos consecutivos dentro de un `VStack` o
`HStack` (incluidas sus variantes `Lazy`) aparece una etiqueta morada con una
flecha (`↕` o `↔`) y el valor de `spacing:` declarado, o `default` si no se
especifico. Se dibuja centrada en el hueco que ocupa la separacion, junto al
borde del elemento anterior.

Por defecto, una vista propia como `ProfileView()` se muestra como un unico
nodo opaco, porque `#LayerPreview` solo ve el codigo escrito dentro de su
propia closure y no el de otras declaraciones. Para que tambien se represente
el contenido de su `body`, anota el tipo con `@LayerPreviewInspectable`:

```swift
@LayerPreviewInspectable
struct ProfileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
            Text("Taylor Morgan")
        }
        .padding(24)
    }
}

#Preview("Profile") {
    #LayerPreview {
        ProfileView()
    }
}
```

`@LayerPreviewInspectable` instrumenta el `body` de ese tipo con la misma
logica que `#LayerPreview` y genera la conformidad necesaria para que el nodo
`ProfileView` en el Canvas muestre, dentro de su propio recuadro, el `VStack`,
`Image` y `Text` que declara. Los tipos que no se anoten siguen mostrandose
como un unico nodo con su nombre.

La macro se expande a `LayerPreviewSurface`. No se utilizan prompts, IA ni se
escriben archivos: el inspector existe solo en el Canvas y es compatible con
macOS, iOS, iPadOS y watchOS.
