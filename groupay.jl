#!/usr/bin/env julia

# ---------------------------------------------------------------------------- #
# groupay.jl :  A simple interactive group payment solution.
#
# Copyright: Zhou Feng @ https://github.com/zfengg/toolkit/tree/master/julia
# ---------------------------------------------------------------------------- #

module Groupay

using Dates

export Member, PayGroup
export main_groupay, gen_paygrp, add_bills!, add_member!
export print_member, print_bill, print_soln

# ---------------------------------------------------------------------------- #
"""
    `Member` struct in the group
"""
mutable struct Member
    name::String
    shouldPay::Dict
    hasPaid::Dict
    Member(name::String) = new(name, Dict(), Dict())
end
get_toPay(m::Member) = sum(values(m.shouldPay)) - sum(values(m.hasPaid))

"""
    PayGroup

    The object contains all the information about group payment.
"""
mutable struct PayGroup
    title::String
    date::Date
    members::Dict
    billMetaInfo::Dict
    billDetails::Dict
    PayGroup(title::String, date::Date) = new(title, date, Dict(), Dict(), Dict())
    PayGroup(title::String) = PayGroup(title, Dates.today())
end

"""
    print_member(m::Member)

    Print payment information of `m`.
"""
function print_member(m::Member)
    println("[\e[36m", m.name, "\e[0m]")
    if isempty(m.hasPaid)
        println("\e[35m No record yet.\e[0m\n")
        return nothing
    end
    println("-- has paid")
    for (k, v) in m.hasPaid
        println("\e[33m", k, "\e[0m : ", v)
    end
    println("total = \e[32m", sum(values(m.hasPaid)), "\e[0m")
    println("-- should pay")
    for (k, v) in m.shouldPay
        println("\e[33m", k, "\e[0m : ", v)
    end
    println("total = \e[31m", sum(values(m.shouldPay)), "\e[0m")
    println("-- remains to pay: \e[35m", get_toPay(m), "\e[0m\n")
end
print_member(s::String, g::PayGroup) = print_member(g.members[s])

"""
    print_member(x::PayGroup)

    Print payment information for all the members in `x::PayGroup`.
"""
function print_member(x::PayGroup)
    println("\n======\n")
    for member in values(x.members)
        print_member(member)
    end
    println("======\n")
end

"""
    gen_paygrp() -> payGrp::PayGroup

    Generate a `PayGroup` interactively.
"""
function gen_paygrp()
    println("What's the name of your group?")
    title = readline()
    while isempty(title)
        println("Why not name your group? ^o^")
        println("Please give it a nice name:")
        title = readline()
    end
    payGrp = PayGroup(title)
    println("And who are in the group \e[31m", title, "\e[0m?")
    members = String[]
    while true
        membersTmp = readline()
        append!(members, split(membersTmp))
        println()
        println("Your group now contains \e[31m", length(members), "\e[0m members:")
        for x in members
            println("\e[36m", x, "\e[0m")
        end
        println()
        println("Do you want to add more members?(y/[n])")
        flagInputName = readline()
        if flagInputName == "y"
            println()
            println("Please add the names of the others:")
        elseif length(members) == 0
            println()
            println("haha~ such a joke that a group with \e[31mNO\e[0m members!")
            println("Please add the names of the others:")
        else
            if length(members) == 1
                println("Oh~ You are the only one in the group.")
                println("Good, we will accompany you. ^_^")
            end
            break
        end
    end

    for name in members
        push!(payGrp.members, name => Member(name))
    end

    return payGrp
end

"""
    add_member!(x::PayGroup) -> x::PayGroup

    Add more members to a `PayGroup` interactively.
"""
function add_member!(payGrp::PayGroup)
    println("Here are the members in \e[31m", payGrp.title, "\e[0m:")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
    end

    println("Who else do you want to add?")
    println("\e[31mWarning\e[0m: Repeated names may crash the whole process ^_^!")
    addMembers = String[]
    while true
        membersTmp = readline()
        append!(addMembers, split(membersTmp))

        println()
        println("The following \e[31m", length(addMembers), "\e[0m members are added:")
        for x in addMembers
            println("\e[36m", x, "\e[0m")
        end
        println()
        println("Do you what to add more members?(y/[n])")
        flagInputName = readline()
        if flagInputName == "y"
            println()
            println("Please add the names of the others:")
        else
            break
        end
    end

    for name in addMembers
        push!(payGrp.members, name => Member(name))
    end

    return payGrp
end

"""
    Generate 'billDetails' from a `::Dict`.
"""
function get_bill_details(m::Dict, billname::String)
    billDetails = Dict()
    for (name, member) in m
        if haskey(member.shouldPay, billname)
            push!(billDetails, member.name => member.shouldPay[billname])
        end
    end
    return billDetails
end
get_bill_details(x::PayGroup, billname::String) = get_bill_details(x.members, billname)

"""
    print_bill(billname::String, x::PayGroup)

    Print the information of bills.
"""
function print_bill(billname::String, x::PayGroup)
    println("[\e[33m", billname, "\e[0m]")
    payTotal = x.billMetaInfo[billname][1]
    payMan = x.billMetaInfo[billname][2]
    println("total = \e[31m", payTotal, "\e[0m paid by \e[36m", payMan, "\e[0m;")
    if x.billMetaInfo[billname][3]
        println("-- \e[34mAA\e[0m --")
    else
        println("-- \e[34mnot AA\e[0m --")
    end
    for (key, val) in x.billDetails[billname]
        println("\e[36m", key, "\e[0m => ", val)
    end
    println()
end

"""
    print_bill(x::PayGroup)

    Print the information of all the bills in `x::PayGroup`.

"""
function print_bill(x::PayGroup)
    println("\n======\n")

    println("Group: \e[91m", x.title, "\e[0m")
    println("Date: \e[95m", x.date, "\e[0m")
    print("Members: \e[36m")
    for name in keys(x.members)
        print(name, " ")
    end
    print("\e[0m\n")
    println("Total: \e[92m", sum(i[1] for i in values(x.billMetaInfo)), "\e[0m")
    println()

    for billname in keys(x.billDetails)
        print_bill(billname, x)
    end
    println("======\n")
end

"""
    add_bills!(payGrp::PayGroup) -> payGrp::PayGroup

    Add bills to a `PayGroup`.
"""
function add_bills!(payGrp::PayGroup)
    println()

    if length(payGrp.members) == 1
        println("Ok, nice to meet you!")
        payMan = undef
        for x in keys(payGrp.members)
            println("\e[36m", x, "\e[0m")
            payMan = x
        end
        println("Then let's review your bills together.")

        println()
        println("What's your first bill to add?")
        countBills = 1
        while true
            # meta info
            billname = readline()
            while isempty(billname)
                println("It's better to give the bill a name, right? ^o^")
                println("So please name your bill:")
                billname = readline()
            end

            println("And how much have you paid for \e[33m", billname, "\e[0m?")
            payTotal = undef
            while true
                try
                    tempExpr = Meta.parse(readline())
                    payTotal = eval(tempExpr) |> Float64
                    println(tempExpr, " = ", payTotal)
                    break
                catch
                    print("Oops, \e[31minvalid\e[0m money input! ")
                    print("Please input a \e[32mnumber\e[0m or \e[32mmath-expression\e[0m:\n")
                end
            end
            for (name, member) in payGrp.members
                if name == payMan
                    push!(member.hasPaid, billname => payTotal)
                else
                    push!(member.hasPaid, billname => 0.)
                end
            end

            isAA = true
            push!(payGrp.members[payMan].shouldPay, billname => payTotal)
            push!(payGrp.billMetaInfo, billname => (payTotal, payMan, isAA))
            billDetails = Dict(payMan => payTotal)
            push!(payGrp.billDetails, billname => billDetails)
            println()
            print_bill(billname, payGrp)

            println()
            println("And do you have another bill?([y]/n)")
            hasNextBill = readline()
            if hasNextBill == "n"
                break
            else
                countBills += 1
                println()
                println("(\e[32mTip:\e[0m Overwrite \e[32many\e[0m previous bill by inputting the same name.)\n")
                println("What's your next bill?")
            end
        end
        return payGrp
    end

    println("Ok, nice to meet you all!")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
    end
    if ! isempty(payGrp.billMetaInfo)
        println("And you have added the following bills:")
        for billname in keys(payGrp.billMetaInfo)
            println("\e[33m", billname, "\e[0m")
        end
        println()
        println("What's your next bill to add?")
    else
        println("Then let's review your bills together.")
        println()
        println("What's your first bill to add?")
    end

    countBills = 1
    while true
        # meta info
        billname = readline()
        while isempty(billname)
            println("It's better to give the bill a name, right? ^o^")
            println("So please name your bill:")
            billname = readline()
        end
        println("Who pays \e[33m", billname, "\e[0m?")
        payMan = undef
        while true
            payMan = readline()
            if payMan in keys(payGrp.members)
                break
            else
                println("Oops, \e[36m", payMan, "\e[0m is not in your group! Please input the name again:")
            end
        end
        println("And how much has \e[36m", payMan, "\e[0m paid?")
        payTotal = undef
        while true
            try
                tempExpr = Meta.parse(readline())
                payTotal = eval(tempExpr) |> Float64
                println(tempExpr, " = ", payTotal)
                break
            catch
                print("Oops, \e[31minvalid\e[0m money input! ")
                print("Please input a \e[32mnumber\e[0m or \e[32mmath-expression\e[0m:\n")
            end
        end
        for (name, member) in payGrp.members
            if name == payMan
                push!(member.hasPaid, billname => payTotal)
            else
                push!(member.hasPaid, billname => 0.)
            end
        end

        # details
        println("Do you \e[34mAA\e[0m?([y]/n)")
        isAA = readline()
        if isAA == "n"
            isAA = false
            billDetails = undef
            while true
                tmpMembers = copy(payGrp.members)
                println("How much should each member pay?")
                for (name, member) in tmpMembers
                    print("\e[36m", name, "\e[0m : ")
                    tmpShouldPay = undef
                    while true
                        try
                            tempExpr = Meta.parse(readline())
                            tmpShouldPay = eval(tempExpr) |> Float64
                            println(tempExpr, " = ", tmpShouldPay)
                            break
                        catch
                            println("\e[31mInvalid\e[0m number expression!")
                            print("\e[36m", name, "\e[0m : ")
                        end
                    end
                    push!(member.shouldPay, billname => tmpShouldPay)
                end

                billDetails = get_bill_details(tmpMembers, billname)
                if payTotal != sum(values(billDetails))
                    println()
                    println("Oops! The sum of money doesn't match the total \e[32m", payTotal, "\e[0m!")
                    println("Please input again.")
                else
                    payGrp.members = tmpMembers
                    break
                end
            end
        else
            isAA = true
            println("\e[34mAA\e[0m on all the members?([y]/n)")
            isAllAA = readline()
            AAlist = []
            if isAllAA == "n"
                println("Check [y]/n ?")
                for name in keys(payGrp.members)
                    print("\e[36m", name, "\e[0m : ")
                    tmpIsAA = readline()
                    if tmpIsAA != "n"
                        push!(AAlist, name)
                    end
                end
            else
                AAlist = keys(payGrp.members)
            end
            avgPay = payTotal / length(AAlist)
            for name in keys(payGrp.members)
                if name in AAlist
                    push!(payGrp.members[name].shouldPay, billname => avgPay)
                else
                    push!(payGrp.members[name].shouldPay, billname => 0.)
                end
            end
        end

        push!(payGrp.billMetaInfo, billname => (payTotal, payMan, isAA))
        billDetails = get_bill_details(payGrp, billname)
        push!(payGrp.billDetails, billname => billDetails)
        println()
        print_bill(billname, payGrp)

        println()
        println("And do you have another bill?([y]/n)")
        hasNextBill = readline()
        if hasNextBill == "n"
            break
        else
            countBills += 1
            println()
            println("(\e[32mTip:\e[0m Overwrite \e[32many\e[0m previous bill by inputting the same name.)\n")
            println("What's your next bill?")
        end
    end
    return payGrp
end

"""
    gen_soln(payGrp::PayGroup) -> soln

    Generate a payment solution from a `PayGroup`.
"""
function gen_soln(payGrp::PayGroup)
    payers = []
    receivers = []
    for (name, member) in payGrp.members
        if isempty(member.hasPaid)
            continue
        end

        tmpToPay = get_toPay(member)
        if tmpToPay == 0
            continue
        elseif tmpToPay > 0
            push!(payers, (name, tmpToPay))
        else
            push!(receivers, (name, -tmpToPay))
        end
    end

    if isempty(payers)
        return [("Everyone", "happy", 0)]
    end

    payers = sort(payers; by=x -> x[2])
    receivers = sort(receivers; by=x -> x[2])
    if abs(sum(map(x -> x[2], payers)) - sum(map(x -> x[2], receivers))) > 0.01
        println("Source does NOT match sink!")
    end

    soln = []
    while ! isempty(receivers)
        tmpPayer = payers[end]
        tmpReceiver = receivers[end]
        tmpDiff = tmpPayer[2] - tmpReceiver[2]
        if tmpDiff > 0.001
            push!(soln, (tmpPayer[1], tmpReceiver[1], tmpReceiver[2]))
            pop!(receivers)
            payers[end] = (tmpPayer[1], tmpDiff)
        elseif tmpDiff < -0.001
            push!(soln, (tmpPayer[1], tmpReceiver[1], tmpPayer[2]))
            pop!(payers)
            receivers[end] = (tmpReceiver[1], - tmpDiff)
        else
            push!(soln, (tmpPayer[1], tmpReceiver[1], tmpPayer[2]))
            pop!(payers)
            pop!(receivers)
        end
    end
    return soln
end

"""
    Print the payment solution.
"""
function print_soln(soln)
    println("\nTada! Here is a \e[32mpayment solution\e[0m :)\n")
    if soln[1][3] == 0
        println("\e[36m Congrats! Everyone is happy. \e[0m")
    else
        for tuple in soln
            println("\e[36m", tuple[1], "\e[0m => \e[36m", tuple[2], "\e[0m : ", tuple[3])
        end
    end
    println()
end
print_soln(x::PayGroup) = print_soln(gen_soln(x))

# # IO via JLD2
# using JLD2: save_object, load_object
# save_paygrp(f::String, g::PayGroup) = save_object(f, g)
# save_paygrp(g::PayGroup) = save_paygrp("groupay.jld2", g)
# load_paygrp(f::String) = load_object(f)
# load_paygrp() = load_paygrp("groupay.jld2")

end # module


# ----------------------------------- main ----------------------------------- #
using .Groupay
run(`clear`)
println("Hi, there! Welcome to happy ~\e[32m group pay \e[0m~")
println("We will provide you a payment solution for your group.")
println()
# input_members
payGrp = gen_paygrp()
# input_bills
payGrp = add_bills!(payGrp)
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
# payment solution
print_soln(payGrp)
# the end
println()
println("Have a good day ~")

bill = print_bill
mem = print_member
sol = print_soln
g = payGrp