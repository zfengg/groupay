#!/usr/bin/env julia

include("../src/Groupay.jl")
using .Groupay

# ----------------------------------- main ----------------------------------- #
run(`clear`)
println("Hi, there! Welcome to happy ~\e[32m group pay \e[0m~")
println("We will provide you a payment solution for your group.")

function startup()
    println()
    if isfile("groupay.jld2")
        println("A saved \e[32mPayGroup\e[0m has been detected!")
        println("Do you want to load it?([y]/n)")
        shouldLoad = readline()
        if shouldLoad == "n"
            println("Then let's start a new group.")
        else
            payGrp = load_paygrp("groupay.jld2")
            println()
            println("The saved group has been loaded! ^_^")
            print_metainfo(payGrp)

            println("Do you want to add more members?(y/[n])")
            shouldAddMem = readline()
            if shouldAddMem == "y"
                payGrp = add_member!(payGrp)
            end
            println()
            println("Current bills:")
            for (d, dateBills) in payGrp.bills
                println("< \e[93m", d, "\e[0m >")
                for billname in keys(dateBills)
                    println("\e[33m", billname, "\e[0m")
                end
            end
            println()
            println("Do you want to add more bills?([y]/n)")
            shouldAddBill = readline()
            if shouldAddBill == "n"
                return payGrp
            end
            payGrp = add_bills!(payGrp)
            return payGrp
        end
    end
    payGrp = gen_paygrp()
    payGrp = add_bills!(payGrp)
    return payGrp
end

payGrp = startup()

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
# ---------------------------------- manual ---------------------------------- #
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
function print_manual(man)
    println("")
    println("\e[35mCommand manual\e[0m:")
    for cmd in man
        println("  \e[32m", cmd[1], "\e[0m : ", cmd[2])
    end
    println("Get help by \e[33m?\e[0m e.g., \e[33m?s\e[0m\n")
end
print_manual(manual)
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

