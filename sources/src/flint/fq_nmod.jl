###############################################################################
#
#   fq_nmod.jl : Flint finite fields
#
###############################################################################

export fq_nmod, FqNmodFiniteField

###############################################################################
#
#   Type and parent object methods
#
###############################################################################

parent_type(::Type{fq_nmod}) = FqNmodFiniteField

elem_type(::Type{FqNmodFiniteField}) = fq_nmod

base_ring(a::FqNmodFiniteField) = Union{}

base_ring(a::fq_nmod) = Union{}

parent(a::fq_nmod) = a.parent

isdomain_type(::Type{fq_nmod}) = true

function check_parent(a::fq_nmod, b::fq_nmod)
   a.parent != b.parent && error("Operations on distinct finite fields not supported")
end

###############################################################################
#
#   Basic manipulation
#
###############################################################################

function Base.hash(a::fq_nmod, h::UInt)
   b = 0x78e5f766c8ace18d%UInt
   for i in 1:degree(parent(a)) + 1
      b = xor(b, xor(hash(coeff(a, i), h), h))
      b = (b << 1) | (b >> (sizeof(Int)*8 - 1))
   end
   return b
end

function coeff(x::fq_nmod, n::Int)
   n < 0 && throw(DomainError())
   return ccall((:nmod_poly_get_coeff_ui, :libflint), UInt,
                (Ref{fq_nmod}, Int), x, n)
end

function zero(a::FqNmodFiniteField)
   d = a()
   ccall((:fq_nmod_zero, :libflint), Void,
         (Ref{fq_nmod}, Ref{FqNmodFiniteField}), d, a)
   return d
end

function one(a::FqNmodFiniteField)
   d = a()
   ccall((:fq_nmod_one, :libflint), Void,
         (Ref{fq_nmod}, Ref{FqNmodFiniteField}), d, a)
   return d
end

function gen(a::FqNmodFiniteField)
   d = a()
   ccall((:fq_nmod_gen, :libflint), Void,
         (Ref{fq_nmod}, Ref{FqNmodFiniteField}), d, a)
   return d
end

iszero(a::fq_nmod) = ccall((:fq_nmod_is_zero, :libflint), Bool,
                     (Ref{fq_nmod}, Ref{FqNmodFiniteField}), a, a.parent)

isone(a::fq_nmod) = ccall((:fq_nmod_is_one, :libflint), Bool,
                    (Ref{fq_nmod}, Ref{FqNmodFiniteField}), a, a.parent)

isgen(a::fq_nmod) = a == gen(parent(a)) # there is no isgen in flint

isunit(a::fq_nmod) = ccall((:fq_nmod_is_invertible, :libflint), Bool,
                     (Ref{fq_nmod}, Ref{FqNmodFiniteField}), a, a.parent)

function characteristic(a::FqNmodFiniteField)
   d = fmpz()
   ccall((:__fq_nmod_ctx_prime, :libflint), Void,
         (Ref{fmpz}, Ref{FqNmodFiniteField}), d, a)
   return d
end

function order(a::FqNmodFiniteField)
   d = fmpz()
   ccall((:fq_nmod_ctx_order, :libflint), Void,
         (Ref{fmpz}, Ref{FqNmodFiniteField}), d, a)
   return d
end

function degree(a::FqNmodFiniteField)
   return ccall((:fq_nmod_ctx_degree, :libflint), Int,
                (Ref{FqNmodFiniteField},), a)
end

function deepcopy_internal(d::fq_nmod, dict::ObjectIdDict)
   z = fq_nmod(parent(d), d)
   z.parent = parent(d)
   return z
end

###############################################################################
#
#   Canonicalisation
#
###############################################################################

canonical_unit(x::fq_nmod) = x

###############################################################################
#
#   AbstractString I/O
#
###############################################################################

function show(io::IO, x::fq_nmod)
   cstr = ccall((:fq_nmod_get_str_pretty, :libflint), Ref{UInt8},
                (Ref{fq_nmod}, Ref{FqNmodFiniteField}), x, x.parent)

   print(io, unsafe_string(cstr))

   ccall((:flint_free, :libflint), Void, (Ref{UInt8},), cstr)
end

function show(io::IO, a::FqNmodFiniteField)
   print(io, "Finite field of degree ", degree(a))
   print(io, " over F_", characteristic(a))
end

needs_parentheses(x::fq_nmod) = x.length > 1

isnegative(x::fq_nmod) = false

show_minus_one(::Type{fq_nmod}) = true

###############################################################################
#
#   Unary operations
#
###############################################################################

function -(x::fq_nmod)
   z = parent(x)()
   ccall((:fq_nmod_neg, :libflint), Void,
       (Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}), z, x, x.parent)
   return z
end

###############################################################################
#
#   Binary operations
#
###############################################################################

function +(x::fq_nmod, y::fq_nmod)
   check_parent(x, y)
   z = parent(y)()
   ccall((:fq_nmod_add, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}),
                                                       z, x, y, y.parent)
   return z
end

function -(x::fq_nmod, y::fq_nmod)
   check_parent(x, y)
   z = parent(y)()
   ccall((:fq_nmod_sub, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}),
                                                       z, x, y, y.parent)
   return z
end

function *(x::fq_nmod, y::fq_nmod)
   check_parent(x, y)
   z = parent(y)()
   ccall((:fq_nmod_mul, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}),
                                                       z, x, y, y.parent)
   return z
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

function *(x::Int, y::fq_nmod)
   z = parent(y)()
   ccall((:fq_nmod_mul_si, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Int, Ref{FqNmodFiniteField}),
                                               z, y, x, y.parent)
   return z
end

*(x::fq_nmod, y::Int) = y*x

*(x::Integer, y::fq_nmod) = fmpz(x)*y

*(x::fq_nmod, y::Integer) = y*x

function *(x::fmpz, y::fq_nmod)
   z = parent(y)()
   ccall((:fq_nmod_mul_fmpz, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fmpz}, Ref{FqNmodFiniteField}),
                                                    z, y, x, y.parent)
   return z
end

*(x::fq_nmod, y::fmpz) = y*x

+(x::fq_nmod, y::Integer) = x + parent(x)(y)

+(x::Integer, y::fq_nmod) = y + x

+(x::fq_nmod, y::fmpz) = x + parent(x)(y)

+(x::fmpz, y::fq_nmod) = y + x

-(x::fq_nmod, y::Integer) = x - parent(x)(y)

-(x::Integer, y::fq_nmod) = parent(y)(x) - y

-(x::fq_nmod, y::fmpz) = x - parent(x)(y)

-(x::fmpz, y::fq_nmod) = parent(y)(x) - y

###############################################################################
#
#   Powering
#
###############################################################################

function ^(x::fq_nmod, y::Int)
   if y < 0
      x = inv(x)
      y = -y
   end
   z = parent(x)()
   ccall((:fq_nmod_pow_ui, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Int, Ref{FqNmodFiniteField}),
                                               z, x, y, x.parent)
   return z
end

function ^(x::fq_nmod, y::fmpz)
   if y < 0
      x = inv(x)
      y = -y
   end
   z = parent(x)()
   ccall((:fq_nmod_pow, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fmpz}, Ref{FqNmodFiniteField}),
                                                    z, x, y, x.parent)
   return z
end

###############################################################################
#
#   Comparison
#
###############################################################################

function ==(x::fq_nmod, y::fq_nmod)
   check_parent(x, y)
   ccall((:fq_nmod_equal, :libflint), Bool,
       (Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}), x, y, y.parent)
end

###############################################################################
#
#   Ad hoc comparison
#
###############################################################################

==(x::fq_nmod, y::Integer) = x == parent(x)(y)

==(x::fq_nmod, y::fmpz) = x == parent(x)(y)

==(x::Integer, y::fq_nmod) = parent(y)(x) == y

==(x::fmpz, y::fq_nmod) = parent(y)(x) == y

###############################################################################
#
#   Inversion
#
###############################################################################

function inv(x::fq_nmod)
   iszero(x) && throw(DivideError())
   z = parent(x)()
   ccall((:fq_nmod_inv, :libflint), Void,
       (Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}), z, x, x.parent)
   return z
end

###############################################################################
#
#   Exact division
#
###############################################################################

function divexact(x::fq_nmod, y::fq_nmod)
   check_parent(x, y)
   iszero(y) && throw(DivideError())
   z = parent(y)()
   ccall((:fq_nmod_div, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}),
                                                       z, x, y, y.parent)
   return z
end

function divides(a::fq_nmod, b::fq_nmod)
   iszero(b) && error("Division by zero in divides")
   return true, divexact(a, b)
end

###############################################################################
#
#   Ad hoc exact division
#
###############################################################################

divexact(x::fq_nmod, y::Integer) = divexact(x, parent(x)(y))

divexact(x::fq_nmod, y::fmpz) = divexact(x, parent(x)(y))

divexact(x::Integer, y::fq_nmod) = divexact(parent(y)(x), y)

divexact(x::fmpz, y::fq_nmod) = divexact(parent(y)(x), y)

###############################################################################
#
#   Special functions
#
###############################################################################

function pth_root(x::fq_nmod)
   z = parent(x)()
   ccall((:fq_nmod_pth_root, :libflint), Void,
       (Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}), z, x, x.parent)
   return z
end

function trace(x::fq_nmod)
   z = fmpz()
   ccall((:fq_nmod_trace, :libflint), Void,
         (Ref{fmpz}, Ref{fq_nmod}, Ref{FqNmodFiniteField}), z, x, x.parent)
   return parent(x)(z)
end

function norm(x::fq_nmod)
   z = fmpz()
   ccall((:fq_nmod_norm, :libflint), Void,
         (Ref{fmpz}, Ref{fq_nmod}, Ref{FqNmodFiniteField}), z, x, x.parent)
   return parent(x)(z)
end

function frobenius(x::fq_nmod, n = 1)
   z = parent(x)()
   ccall((:fq_nmod_frobenius, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Int, Ref{FqNmodFiniteField}),
                                               z, x, n, x.parent)
   return z
end

###############################################################################
#
#   Unsafe functions
#
###############################################################################

function zero!(z::fq_nmod)
   ccall((:fq_nmod_zero, :libflint), Void,
        (Ref{fq_nmod}, Ref{FqNmodFiniteField}), z, z.parent)
   return z
end

function mul!(z::fq_nmod, x::fq_nmod, y::fq_nmod)
   ccall((:fq_nmod_mul, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}),
                                                       z, x, y, y.parent)
   return z
end

function addeq!(z::fq_nmod, x::fq_nmod)
   ccall((:fq_nmod_add, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}),
                                                       z, z, x, x.parent)
   return z
end

function add!(z::fq_nmod, x::fq_nmod, y::fq_nmod)
   ccall((:fq_nmod_add, :libflint), Void,
         (Ref{fq_nmod}, Ref{fq_nmod}, Ref{fq_nmod}, Ref{FqNmodFiniteField}),
                                                       z, x, y, x.parent)
   return z
end

###############################################################################
#
#   Promotions
#
###############################################################################

promote_rule(::Type{fq_nmod}, ::Type{T}) where {T <: Integer} = fq_nmod

promote_rule(::Type{fq_nmod}, ::Type{fmpz}) = fq_nmod

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (a::FqNmodFiniteField)()
   z = fq_nmod(a)
   z.parent = a
   return z
end

(a::FqNmodFiniteField)(b::Integer) = a(fmpz(b))

function (a::FqNmodFiniteField)(b::Int)
   z = fq_nmod(a, b)
   z.parent = a
   return z
end

function (a::FqNmodFiniteField)(b::fmpz)
   z = fq_nmod(a, b)
   z.parent = a
   return z
end

function (a::FqNmodFiniteField)(b::fq_nmod)
   parent(b) != a && error("Coercion between finite fields not implemented")
   return b
end

###############################################################################
#
#   FlintFiniteField constructor
#
###############################################################################

function FlintFiniteField(char::Int, deg::Int, s::AbstractString; cached = true)
   S = Symbol(s)
   parent_obj = FqNmodFiniteField(fmpz(char), deg, S, cached)

   return parent_obj, gen(parent_obj)
end

function FlintFiniteField(pol::nmod_poly, s::AbstractString; cached = true)
   S = Symbol(s)
   parent_obj = FqNmodFiniteField(pol, S, cached)

   return parent_obj, gen(parent_obj)
end
