rem ======================================================
rem                     EXPRESSIONS
rem ======================================================

rem Forward declarations.
type Expression_ as Expression
type TypeName_ as TypeName
type AssignmentExpression_ as AssignmentExpression
type InitializerList_ as InitializerList
type CastExpression_ as CastExpression

type Identifier
    value as String
end type

const INTEGER_CONSTANT as uinteger = 0
const FLOATING_CONSTANT as uinteger = 2
const ENUMERATION_CONSTANT as uinteger = 1
const CHARACTER_CONSTANT as uinteger = 3

type EnumerationConstant as Identifier

type Constant
    type as uinteger
    union
        as_integer as integer
        as_float as double
        as_enum as EnumerationConstant ptr
        as_character as string * 1
    end union
end type

type StringLiteral
    value as string ptr
end type

const IDENTIFIER_PRIMARY = 0
const CONSTANT_PRIMARY = 1
const STRING_LITERAL_PRIMARY = 2
const PARENTHESISED_PRIMARY = 3


type PrimaryExpression
    type as uinteger
    union
        as_identifier as Identifier ptr
        as_constant as Constant ptr
        as_string_literal as StringLiteral ptr
        as_parenthesised as Expression_ ptr
    end union
end type

type ArgumentExpressionList
    prev as ArgumentExpressionList ptr
    expression as AssignmentExpression_ ptr
end type

const PRIMARY_EXPRESSION = 0
const ARRAY_ACCESS = 1
const FUNCTION_CALL = 2
const MEMBER_ACCESS = 3
const MEMBER_DEREFERENCE = 4
const POSTFIX_INCREMENT = 5
const POSTFIX_DECREMENT = 6
const COMPOUND_LITERAL = 7

type PostfixExpression
    type as uinteger
    union
        as_primary_expression as PrimaryExpression ptr
        type
            as_array_access_target as PostfixExpression ptr
            as_array_access_index as Expression_ ptr
        end type
        type
            as_function_call_target as PostfixExpression ptr
            as_function_call_arguments as ArgumentExpressionList ptr
        end type
        type
            as_member_access_target as PostfixExpression ptr
            as_member_access_member as Identifier ptr
        end type
        type
            as_member_dereference_target as PostfixExpression ptr
            as_member_dereference_member as Identifier ptr
        end type
        as_postfix_increment as PostfixExpression ptr
        as_postfix_decrement as PostfixExpression ptr
        type
            as_compound_literal_type as TypeName_ ptr
            as_compound_literal_initializers as InitializerList_ ptr
        end type
    end union
end type

const POSTFIX_EXPRESSION = 0
const PREFIX_INCREMENT = 1
const PREFIX_DECREMENT = 2
const UNARY_OPERATION = 3
const SIZEOF_EXPRESSION = 4
const SIZEOF_TYPE = 5

const UNARY_AND = 0
const UNARY_DEREFERENCE = 1
const UNARY_PLUS = 2
const UNARY_MINUS = 3
const UNARY_BITWISE_NOT = 4
const UNARY_NOT = 5

type UnaryExpression
    type as uinteger
    union
        as_postfix_expression as PostfixExpression ptr
        as_prefix_increment as UnaryExpression ptr
        as_prefix_decrement as UnaryExpression ptr
        type
            as_unary_operation_operator as uinteger
            as_unary_operation_target as CastExpression_ ptr
        end type
        as_sizeof_expression as UnaryExpression ptr
        as_sizeof_type as TypeName_ ptr
    end union
end type

type CastExpression
    type_name as TypeName_ ptr
    expression as UnaryExpression ptr
end type

const BINARY_TIMES = 0
const BINARY_DIVIDE = 1
const BINARY_MODULO = 3

type MultiplicativeExpression
    has_operation as boolean
    union
        as_cast_expression as CastExpression ptr
        type
            as_operation_lhs as MultiplicativeExpression ptr
            as_operation_operator as uinteger
            as_operation_rhs as CastExpression ptr
        end type
    end union    
end type

const BINARY_PLUS = 1
const BINARY_MINUS = 2

type AdditiveExpression
    has_operation as boolean
    union
        as_multiplicative_expression as MultiplicativeExpression ptr
        type
            as_operation_lhs as AdditiveExpression ptr
            as_operation_operator as uinteger
            as_operation_rhs as MultiplicativeExpression ptr
        end type
    end union
end type


const LEFT_SHIFT = 1
const RIGHT_SHIFT = 2

type ShiftExpression
    has_operation as boolean
    union
        as_additive_expression as AdditiveExpression ptr
        type
            as_operation_lhs as ShiftExpression ptr
            as_operation_operator as uinteger
            as_operation_rhs as AdditiveExpression ptr
        end type
    end union
end type


const LESS_THAN = 0
const GREATER_THAN = 1
const LESS_THAN_OR_EQUAL = 2
const GREATER_THAN_OR_EQUAL = 3

type RelationalExpression
    has_operation as boolean
    union
        as_shift_expression as ShiftExpression ptr
        type
            as_operation_lhs as RelationalExpression ptr
            as_operation_operator as uinteger
            as_operation_rhs as ShiftExpression ptr
        end type
    end union
end type


const EQUAL = 0
const NOT_EQUAL = 1

type EqualityExpression
    has_operation as boolean
    union
        as_relational_expression as RelationalExpression ptr
        type
            as_operation_lhs as EqualityExpression ptr
            as_operation_operator as uinteger
            as_operation_rhs as RelationalExpression ptr
        end type
    end union
end type

type AndExpression
    lhs as AndExpression ptr
    rhs as EqualityExpression ptr
end type

type ExclusiveOrExpression
    lhs as ExclusiveOrExpression ptr
    rhs as AndExpression ptr
end type

type InclusiveOrExpression
    lhs as InclusiveOrExpression ptr
    rhs as ExclusiveOrExpression ptr
end type

type LogicalAndExpression
    lhs as LogicalAndExpression ptr
    rhs as InclusiveOrExpression ptr
end type

type LogicalOrExpression
    lhs as LogicalOrExpression ptr
    rhs as LogicalAndExpression ptr
end type

type ConditionalExpression
    has_operation as boolean
    union
        as_logical_or_expression as LogicalOrExpression ptr
        type
            as_conditional_condition as LogicalOrExpression ptr
            as_conditional_truthy as Expression_ ptr
            as_conditional_falsy as ConditionalExpression ptr
        end type
    end union
end type

const SET = 0
const TIMES_SET = 1
const DIVIDE_SET = 2
const MODULO_SET = 3
const PLUS_SET = 4
const MINUS_SET = 5
const LEFT_SHIFT_SET = 6
const RIGHT_SHIFT_SET = 7
const BITWISE_AND_SET = 8
const BITWISE_XOR_SET = 9
const BITWISE_OR_SET = 10

type AssignmentExpression
    has_operation as boolean
    union
        as_conditional_expression as ConditionalExpression ptr
        type
            as_assignment_target as UnaryExpression ptr
            as_assignment_operator as uinteger
            as_assignment_expression as AssignmentExpression ptr
        end type
    end union
end type

type Expression
    prev as Expression ptr
    expression as AssignmentExpression ptr
end type

type ConstantExpression as ConditionalExpression

rem ======================================================
rem                     DECLARATIONS
rem ======================================================

rem Forward declarations.
type TypeSpecifier_ as TypeSpecifier
type Declarator_ as Declarator
type DeclarationSpecifiers_ as DeclarationSpecifiers
type StructDeclaratorList_ as StructDeclaratorList
type Pointer__ as Pointer_
type AbstractDeclarator_ as AbstractDeclarator
type ParameterTypeList_ as ParameterTypeList
type Initializer_ as Initializer

const ARRAY_DESIGNATOR = 0
const MEMBER_DESIGNATOR = 1

type Designator
    type as uinteger
    union
        as_array_index as ConstantExpression ptr
        as_member as Identifier ptr
    end union
end type

type DesignatorList
    designator as Designator ptr
    prev as DesignatorList ptr
end type

type Designation as DesignatorList

type InitializerList
    prev as InitializerList ptr
    designation as Designation ptr
    initializer as Initializer_ ptr
end type


const ASSIGNMENT_EXPRESSION_INITIALIZER = 0
const INITIALIZER_LIST_INITIALIZER = 1

type Initializer
    type as uinteger
    union
        as_assignment_expression as AssignmentExpression ptr
        as_initializer_list as InitializerList ptr
    end union
end type

type TypedefName as Identifier

type SpecifierQualifierList
    type as uinteger
    union
        as_type_specifier as TypeSpecifier_ ptr
        as_type_qualifier as uinteger
    end union
end type

const PARENTHESISED_ABSTRACT_DECLARATOR = 0
const ARRAY_ABSTRACT_DECLARATOR = 1
const FUNCTION_ABSTRACT_DECLARATOR = 2

type DirectAbstractDeclarator
    type as uinteger
    union
        as_parenthesised as AbstractDeclarator_ ptr
        type
            as_array_base_declarator as DirectAbstractDeclarator ptr
            as_array_size as AssignmentExpression ptr
            as_array_is_variable_length as boolean
        end type
        type
            as_function_base_declarator as DirectAbstractDeclarator ptr
            as_function_parameters as ParameterTypeList_ ptr
        end type
    end union
end type

type AbstractDeclarator
    pointer_ as Pointer__ ptr
    direct_abstract_declarator as DirectAbstractDeclarator ptr
end type

type TypeName
    specifier_qualifier_list as SpecifierQualifierList ptr
    abstract_declarator as AbstractDeclarator ptr
end type

type TypeQualifierList
    qualifier as uinteger
    prev as TypeQualifierList ptr
end type

type ParameterDeclaration
    specifiers as DeclarationSpecifiers_ ptr
    declarator as Declarator_ ptr
    abstract_declarator as AbstractDeclarator ptr
end type

type ParameterList
    declaration as ParameterDeclaration ptr
    prev as ParameterList ptr
end type

type ParameterTypeList
    parameter_list as ParameterList ptr
    has_varargs as boolean
end type

type IdentifierList
    identifier as Identifier ptr
    prev as IdentifierList ptr
end type

const IDENTIFIER_DECLARATOR = 0
const PARENTHESISED_DECLARATOR = 1
const ARRAY_DECLARATOR = 2
const FUNCTION_DECLARATOR = 3

type DirectDeclarator
    type as uinteger
    union
        as_identifier as Identifier ptr
        as_parenthesised as Declarator_ ptr
        type
            as_array_base as DirectDeclarator ptr
            as_array_qualifiers as TypeQualifierList ptr
            as_array_size as AssignmentExpression ptr
            is_pointer as boolean
        end type
        type
            as_function_base as DirectDeclarator ptr
            as_function_parameter_types as ParameterTypeList ptr
            as_function_parameters as IdentifierList ptr
        end type
    end union
end type

type Pointer_
    type_qualifier_list as TypeQualifierList ptr
    pointer_ as Pointer_ ptr
end type

type Declarator
    pointer_ as Pointer_ ptr
    direct_declarator as DirectDeclarator ptr
end type

type Enumerator 
    constant as EnumerationConstant ptr
    expression as ConstantExpression ptr
end type

type EnumeratorList
    enumerator as Enumerator ptr
    prev as EnumeratorList ptr
end type

type EnumSpecifier
    identifier as Identifier ptr
    enumerator_list as EnumeratorList ptr
end type


type StructDeclarator
    declarator as Declarator ptr
    expression as ConstantExpression ptr
end type

type StructDeclaration
    specifier_qualifier_list as SpecifierQualifierList ptr
    struct_declarator_list as StructDeclaratorList_ ptr
end type

type StructDeclarationList
    prev as StructDeclarationList ptr
    declaration as StructDeclaration ptr
end type

type StructDeclaratorList
    declarator as StructDeclarator ptr
    prev as StructDeclarationList ptr
end type

const IS_STRUCT = 0
const IS_UNION = 1

type StructOrUnionSpecifier
    struct_or_union as uinteger
    identifier as Identifier ptr
    declaration_list as StructDeclarationList ptr
end type

const IS_RESERVED_TYPE = 0
const IS_STRUCT_OR_UNION = 1
const IS_ENUM = 2
const IS_TYPEDEF_NAME = 3

const VOID_TYPE = 0
const CHAR_TYPE = 1
const SHORT_TYPE = 2
const INT_TYPE = 3
const LONG_TYPE = 4
const FLOAT_TYPE = 5
const DOUBLE_TYPE = 6
const SIGNED_TYPE = 7
const UNSIGNED_TYPE = 8
const _BOOL_TYPE = 9
const _COMPLEX_TYPE = 10
const _IMAGINARY_TYPE = 11

type TypeSpecifier
    type as uinteger
    union
        as_reserved_type as uinteger
        as_struct_or_union as StructOrUnionSpecifier ptr
        as_enum as EnumSpecifier ptr
        as_typedef_name as TypedefName ptr
    end union
end type

const IS_TYPEDEF = 0
const IS_EXTERN = 1
const IS_STATIC = 2
const IS_AUTO = 3
const IS_REGISTER = 4

const IS_CONST = 0
const IS_RESTRICT = 1
const IS_VOLATILE = 2

const IS_INLINE = 0

const STORAGE_CLASS_SPECIFIER = 0
const TYPE_SPECIFIER = 1
const TYPE_QUALIFIER = 2
const FUNCTION_SPECIFIER = 3

type DeclarationSpecifiers
    type as uinteger
    union
        as_storage_class_specifier as uinteger
        as_type_specifier as TypeSpecifier ptr
        as_type_qualifier as uinteger
        as_function_specifier as uinteger
    end union
    next as  DeclarationSpecifiers ptr
end type

type InitDeclarator
    declarator as Declarator ptr
    initializer as Initializer ptr
end type

type InitDeclaratorList
    prev as InitDeclaratorList ptr
    declarator as InitDeclarator ptr
end type

type Declaration
    declaration_specifiers as DeclarationSpecifiers ptr
    init_declarator_list as InitDeclaratorList ptr
end type
