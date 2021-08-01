#!/usr/bin/env julia

include("../src/Groupay.jl")
using .Groupay

# ----------------------------------- main ----------------------------------- #
run(`clear`)
println("Hi, there! Welcome to happy ~\e[32m group pay \e[0m~")
println("We will provide you a payment solution for your group.")
println()
# input_members
payGrp = gen_paygrp()
# input_bills
payGrp = add_bills!(payGrp)
# payment solution
print_soln(payGrp)
println()
println("Show detailed information?(y/[n])")
willContinue = readline()
if willContinue != "y"
    println()
    println("Have a good day ~")
    exit()
end
# print bills
println()
println("Show all the bills?([y]/n)")
ynFlag = readline()
if ynFlag == "n"
else
    print_bill(payGrp)
end
# print bills of members
println("And show all the bills based on members?([y]/n)")
ynFlag = readline()
if ynFlag == "n"
else
    print_member(payGrp)
end
# continue
println("Continue to check out info?(y/[n])")
willContinue = readline()
if willContinue != "y"
    println()
    println("Have a good day ~")
    exit()
end

## cmds
"""
    g::PayGroup

the alias for your group
"""
g = payGrp

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

