#!/usr/bin/env julia

include("../src/Groupay.jl")
using .Groupay

payGrp = main_interactive()

# ----------------------------------- alias ---------------------------------- #
g = payGrp
"""
the show meta-info of your group
"""
gm() = print_metainfo(g)

"""
    s()

show payment solution
"""
s() = print_soln(g)

"""
    b()

show all bills
"""
b() = print_bill(g)
"""
    b(s::String)

show bill with name \e[33ms\e[0m
"""
b(s::String) = print_bill(g, s)
b(s::String, d) = print_bill(g, s, d)

bt() = print_bill_today(g)

"""
    m()

show bills of all members
"""
m() = print_member(g)
"""
    m(s::String)

show bills of member \e[36mx\e[0m
"""
m(s::String) = print_member(g, s)
m(s::String, d) = print_member(g, s, d)

"""
print today's info of a member
"""
mt() = print_member_today(g)
mt(s::String) = print_member_today(g, s)

"""
    am()

add members to your group
"""
am() = add_member!(g)

"""
    ab()

add bills to your group
"""
ab() = add_bills!(g)
ab(d) = add_bills!(g, d)

"""
    sg()

save your group
"""
sg() = save_paygrp(g)

"""
    lg()

load your group
"""
lg() = load_paygrp("groupay.jld2")
dg() = rm("groupay.jld2") && println("\e[31mgroupap.jl\e[0m deleted!")
