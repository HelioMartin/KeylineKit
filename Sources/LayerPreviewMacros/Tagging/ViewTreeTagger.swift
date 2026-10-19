import SwiftSyntax

/// Walks a ViewBuilder body and hands every view expression to
/// `ViewNodeRewriter`. Control flow (`if`, `switch`, `#if`) is entered rather
/// than wrapped, so the views inside each branch are instrumented too.
enum ViewTreeTagger {
    static func tag(_ closure: ClosureExprSyntax) -> ClosureExprSyntax {
        closure.with(\.statements, tag(closure.statements))
    }

    static func tag(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        CodeBlockItemListSyntax(statements.map { $0.with(\.item, tag($0.item)) })
    }

    static func tag(_ expr: ExprSyntax) -> ExprSyntax {
        if let ifExpr = expr.as(IfExprSyntax.self) {
            return ExprSyntax(tag(ifExpr))
        }
        if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return ExprSyntax(tag(switchExpr))
        }
        return ViewNodeRewriter.rewrite(expr)
    }

    private static func tag(_ item: CodeBlockItemSyntax.Item) -> CodeBlockItemSyntax.Item {
        switch item {
        case .expr(let expr):
            return .expr(tag(expr))
        case .stmt(let stmt):
            if let expressionStmt = stmt.as(ExpressionStmtSyntax.self) {
                return .stmt(StmtSyntax(expressionStmt.with(\.expression, tag(expressionStmt.expression))))
            }
            if let returnStmt = stmt.as(ReturnStmtSyntax.self), let expression = returnStmt.expression {
                return .stmt(StmtSyntax(returnStmt.with(\.expression, tag(expression))))
            }
            return item
        case .decl(let decl):
            guard let ifConfig = decl.as(IfConfigDeclSyntax.self) else { return item }
            return .decl(DeclSyntax(tag(ifConfig)))
        }
    }

    private static func tag(_ ifExpr: IfExprSyntax) -> IfExprSyntax {
        var result = ifExpr.with(\.body, ifExpr.body.with(\.statements, tag(ifExpr.body.statements)))
        switch ifExpr.elseBody {
        case .ifExpr(let nested):
            result.elseBody = .ifExpr(tag(nested))
        case .codeBlock(let block):
            result.elseBody = .codeBlock(block.with(\.statements, tag(block.statements)))
        case nil:
            break
        }
        return result
    }

    private static func tag(_ switchExpr: SwitchExprSyntax) -> SwitchExprSyntax {
        let cases = switchExpr.cases.map { element -> SwitchCaseListSyntax.Element in
            guard case .switchCase(let switchCase) = element else { return element }
            return .switchCase(switchCase.with(\.statements, tag(switchCase.statements)))
        }
        return switchExpr.with(\.cases, SwitchCaseListSyntax(cases))
    }

    private static func tag(_ ifConfig: IfConfigDeclSyntax) -> IfConfigDeclSyntax {
        let clauses = ifConfig.clauses.map { clause -> IfConfigClauseSyntax in
            guard case .statements(let statements) = clause.elements else { return clause }
            return clause.with(\.elements, .statements(tag(statements)))
        }
        return ifConfig.with(\.clauses, IfConfigClauseListSyntax(clauses))
    }
}
