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
manual = [
    ("g", "the alias for your group")
    ("s()", "show payment solution")
    ("b()", "show all bills")
    ("b(\"x\")", "show bill with name \e[33mx\e[0m")
    ("m()", "show bills of all members")
    ("m(\"x\")", "show bills of member \e[36mx\e[0m")
    ("am()", "add members to your group")
    ("ab()", "add bills to your group")
    ("sg()", "save your group")
    ("lg()", "load your group")
]
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
    b(x::String)

show bill with name \e[33mx\e[0m
"""
b(x::String) = print_bill(g, x, today())

"""
    m()

show bills of all members
"""
m() = print_member(g)

"""
    m(x::String)

show bills of member \e[36mx\e[0m
"""
m(x::String) = print_member(g, x)

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

function print_manual(man)
    println("")
    println("\e[35mCommand manual\e[0m:")
    for cmd in man
        println("  \e[32m", cmd[1], "\e[0m : ", cmd[2])
    end
    println("Get help by \e[33m?\e[0m e.g., \e[33m?s\e[0m\n")
end

print_manual(manual)