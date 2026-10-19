# LayerPreview

`#LayerPreview` dibuja sobre una vista SwiftUI cómo está construido su layout:
el nombre y los límites de cada capa, el padding y el spacing **medidos** en
puntos, los tamaños, los radios de esquina y el área segura del dispositivo.
El lenguaje visual está inspirado en [safearea.info](https://safearea.info):
regiones rellenas, cotas con marcas en los extremos y valores en etiquetas
monoespaciadas.

```swift
import LayerPreview
import SwiftUI

#Preview("Profile layers") {
    #LayerPreview {
        VStack(spacing: 16) {
            ProfileView()
        }
        .padding(24)
    }
}
```

Requiere iOS 16, macOS 13 o watchOS 9. La macro analiza la closure con
SwiftSyntax al compilar; el código de producción no cambia.

## Anotaciones

Sin argumentos se dibujan `.layers`, `.padding` y `.spacing`. Para elegir otras,
pásalas como argumentos:

```swift
#LayerPreview(.padding, .corners) { ProfileView() }
#LayerPreview(.safeArea, .layers) { AccountScreen() }
#LayerPreview(.layers, showContainerLines: false) { ProfileView() }
```

| Anotación | Qué dibuja | Color |
|---|---|---|
| `.layers` | Nombre de cada capa junto a sus límites | Azul `#1447E6` |
| `.padding` | Banda rellena de cada `.padding(...)`, con una cota por borde y el contorno del contenido en verde | Naranja `#CA3500` |
| `.spacing` | Hueco entre hermanos de un `VStack`/`HStack` (y sus variantes `Lazy`) | Morado `#8200DB` |
| `.size` | Cotas de ancho y alto de cada capa, con líneas de extensión discontinuas | Pizarra `#314158` |
| `.corners` | Arco y radio de `cornerRadius:` o `.cornerRadius(_:)` | Rosa `#C6005C` |
| `.safeArea` | Insets del dispositivo (`TOP 62`, `BOTTOM 34`), contorno `SAFE AREA` y, en iOS 27.1+, las regiones reservadas como la Dynamic Island | Naranja, verde y morado |
| `.none` | Nada; los contornos dependen de `showContainerLines` | — |

Los contornos azules de cada capa se dibujan por defecto. Para ocultarlos,
usa `showContainerLines: false`.

### Valor medido frente a valor declarado

Las cifras se miden en tiempo de ejecución, así que muestran lo que SwiftUI
aplica de verdad. Si el código no lo deja claro, el valor declarado aparece al
lado:

- `.padding(24)` → `24`
- `.padding()` → `16 · default`
- `VStack(spacing: Theme.spacing)` → `12 · Theme.spacing`

Las etiquetas se colocan juntas en una sola capa y nunca se solapan. Si un valor
secundario (las cotas de `.size`) no cabe, se omite en vez de tapar a otro.

## Vistas propias: `@LayerPreviewInspectable`

`#LayerPreview` solo ve el código de su propia closure, así que una vista propia
como `ProfileView()` aparece como una única capa. Para que también se dibuje el
interior de su `body`, anota el tipo:

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
```

La macro añade una copia instrumentada del `body`, con el mismo nivel de acceso
que el tipo. Cuando una vista y la raíz de su `body` ocupan el mismo marco,
comparten etiqueta: `ProfileView › VStack`.

## Qué se instrumenta

- Cualquier inicializador con nombre en mayúscula (`VStack`, `ScrollView`,
  `NavigationStack`, `CustomCard`…) se recorre por dentro, incluidas sus
  closures `label:`, `header:`, `footer:`, etc.
- Se entra en las ramas de `if`, `switch` y `#if`.
- `ForEach` y `Group` sin modificadores son transparentes: sus hijos cuentan
  como hermanos del stack que los contiene.
- No se tocan las closures que son acciones o que no contienen vistas:
  `Button("Guardar") { guardar() }`, `TextField`, `Canvas`, `Chart`, `Map` y
  `Table`. `Button(action:) { … }` y `Button { … } label: { … }` sí instrumentan
  su etiqueta.
- Los literales que Xcode reescribe en el Canvas (`__designTimeInteger(…)`)
  se muestran con su valor.

## Cómo funciona

1. **Macro** (`Sources/LayerPreviewMacros`): envuelve cada vista en
   `_LayerPreviewNode` e inserta *probes* antes y después de cada `.padding(...)`
   y tras cada modificador con `cornerRadius`.
2. **Medición** (`Sources/LayerPreview/Measurement`): cada nodo y cada probe
   registra su marco global con `onGeometryChange` en un `LayerPreviewRegistry`.
   Funciona también dentro de `NavigationStack` y `ScrollView`. Los nodos solo
   escriben en el registro; únicamente el canvas lo observa.
3. **Dibujo** (`Sources/LayerPreview/Rendering`): `AnnotationLayout` convierte
   las medidas en regiones, cotas y etiquetas (lógica pura y testeada), y
   `AnnotationCanvas` lo dibuja todo en un único `Canvas`.

Los tipos con prefijo `_` son públicos solo porque los usa el código que genera
la macro; están ocultos en la documentación.

## Estructura del proyecto

```
Sources/
  LayerPreview/            Macros, anotaciones y protocolo públicos
    Support/               API para el código expandido (_LayerPreviewNode, …)
    Measurement/           Registro, marcos medidos y área segura
    Rendering/             Layout de anotaciones, colocación de etiquetas, tema y canvas
  LayerPreviewMacros/      Plugin de compilador
    Tagging/               Recorrido del árbol de vistas, cadenas de modificadores y argumentos
Tests/
  LayerPreviewMacrosTests/ Expansiones de la macro (Swift Testing)
  LayerPreviewTests/       Layout, formato, colocación y registro
Examples/LayerPreviewDemo/ App de ejemplo para iOS y macOS (Shared/, iOS/, macOS/)
```

## Desarrollo

```sh
swift test
```

Si `xcode-select` apunta a las Command Line Tools, SwiftPM no encuentra las
macros de SwiftUI del SDK (`@State`, `@Entry`). En ese caso, usa el toolchain
de Xcode:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

La demo (`Examples/LayerPreviewDemo/LayerPreviewDemo.xcodeproj`) incluye un
`#Preview` por anotación. La app de iOS también muestra la capa anotada en
tiempo de ejecución con un argumento de lanzamiento (`defaults`, `safeArea` o
`details`):

```sh
xcrun simctl launch booted com.layerpreview.demo.ios -LayerPreviewOverlay safeArea
```

## Limitaciones

- `.corners` lee el radio de los modificadores. No lo lee de una forma raíz
  como `RoundedRectangle(cornerRadius:)` usada directamente como vista.
- Una vista propia con modificadores (`ProfileView().padding()`) se dibuja
  como una sola capa, aunque esté anotada con `@LayerPreviewInspectable`.
- Las regiones reservadas de `.safeArea` necesitan compilar con el SDK de
  iOS 27.1 y ejecutar en iOS 27.1 o posterior.
