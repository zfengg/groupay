#!/usr/bin/env julia
# ---------------------------------------------------------------------------- #
#       ______
#      / ____/________  __  ______  ____ ___  __
#     / / __/ ___/ __ \/ / / / __ \/ __ `/ / / /
#    / /_/ / /  / /_/ / /_/ / /_/ / /_/ / /_/ /
#    \____/_/   \____/\__,_/ .___/\__,_/\__, /
#                         /_/          /____/
#
#   A simple interactive group payment solution.
#
# Copyright: Zhou Feng @ https://github.com/zfengg/groupay
# ---------------------------------------------------------------------------- #
module Groupay

using Dates

export Bill, Member, PayGroup
export main_groupay, gen_paygrp, add_bills!, add_member!
export print_member, print_bill, print_soln, print_metainfo
export print_bill_today, print_member_today

# ---------------------------------- structs --------------------------------- #
"""
    `Bill` struct in the group
"""
mutable struct Bill
    billname::String
    date::Date
    total::Float64
    isAA::Bool
    paidPy::String
    shouldPay::Dict{String, Float64}
    Bill(bill::Bill) = new(bill.billname, bill.date, bill.total, bill.isAA, bill.paidPy, Dict())
    Bill(bn::String, d::Date) = new(bn, d, NaN, true, "", Dict())
end

"""
    `Member` struct in the group
"""
mutable struct Member
    name::String
    shouldPay::Dict{Date, Dict{String}{Float64}}
    hasPaid::Dict{Date, Dict{String}{Float64}}
    Member(m::String) = new(m, Dict(), Dict())
end

"""
    PayGroup

    The object contains all the information about group payment.
"""
mutable struct PayGroup
    title::String
    members::Dict{String, Member}
    bills::Dict{Date, Dict{String, Bill}}
    PayGroup(title::String) = new(title, Dict(), Dict())
end

# ------------------------------------ get ----------------------------------- #
get_haspaid(m::Member, d::Date) = haskey(m.hasPaid, d) ? sum(values(m.hasPaid[d])) : 0.
get_haspaid(m::Member, d) = get_haspaid(m, Date(d))
get_haspaid(g::PayGroup, m::String, d) = get_haspaid(g.members[m], d)
get_haspaid(m::Member) = isempty(m.hasPaid) ? 0. : sum(v for d in keys(m.hasPaid) for v in values(m.hasPaid[d]))

get_shouldpay(m::Member, d::Date) = haskey(m.shouldPay, d) ? sum(values(m.shouldPay[d])) : 0.
get_shouldpay(m::Member, d) = get_shouldpay(m, Date(d))
get_shouldpay(g::PayGroup, m::String, d) = get_shouldpay(g.members[m], d)
get_shouldpay(m::Member) = isempty(m.shouldPay) ? 0. : sum(v for d in keys(m.shouldPay) for v in values(m.shouldPay[d]))

get_topay(m::Member, d::Date) = get_shouldpay(m, d) - get_haspaid(m, d)
get_topay(m::Member, d) = get_topay(m, Date(d))
get_topay(g::PayGroup, m::String, d) = get_shouldpay(g, m, d) -get_haspaid(g, m, d)
get_topay(m::Member) = get_shouldpay(m) - get_haspaid(m)

get_total(g::PayGroup, d::Date) = haskey(g.bills, d) ? sum(b.total for b in values(g.bills[d])) : 0.
get_total(g::PayGroup, d) = get_total(g, Date(d))


# ----------------------------------- print ---------------------------------- #
"""
    print_member(m::Member, d::Date)

    Print payment information of `m` on `d`.
"""
function print_member(m::Member, d::Date, showName::Bool=true)
    if showName
        println("[\e[36m", m.name, "\e[0m]")
    end
    flagHasPaid = haskey(m.hasPaid, d)
    flagShouldPay = haskey(m.hasPaid, d)
    
    if !flagHasPaid && !flagShouldPay
        return nothing
    end
    println("< \e[93m", d, "\e[0m >")``

    if flagHasPaid
        println("-- has paid")
        for (k, v) in m.hasPaid[d]
            println("\e[33m", k, "\e[0m : ", v)
        end
        println("total = \e[32m", get_haspaid(m, d), "\e[0m")
    end
    if flagShouldPay
        println("-- should pay")
        for (k, v) in m.shouldPay[d]
            println("\e[33m", k, "\e[0m : ", v)
        end
        println("total = \e[31m", get_shouldpay(m, d), "\e[0m")
    end
    println("-- remains to pay: \e[35m", get_topay(m, d), "\e[0m\n")
    return nothing
end
print_member(m::Member, d, showName::Bool=true) = print_member(m, Date(d), showName)
function print_member(m::Member)
    println("[\e[36m", m.name, "\e[0m]")
    dates = union([x[1] for x in m.hasPaid], [y[1] for y in m.shouldPay])
    for d in dates
        print_member(m, d, false)
    end
end
"""
    print_member(g::PayGroup)

    Print payment information for all the members in `g`.
"""
function print_member(g::PayGroup)
    println("\n======\n")
    for m in values(g.members)
        print_member(m)
        println()
    end
    println("======\n")
end
print_not_in_group(s::String) = println("Sorry, \e[36m", s, "\e[0m is in your group!")
print_member(g::PayGroup, s::String, d::Date) = haskey(g.members, s) ? print_member(g.members[s], d) : print_not_in_group(s)
print_member(g::PayGroup, s::String, d) = print_member(g::PayGroup, s, Date(d))
print_member(g::PayGroup, s::String) = haskey(g.members, s) ? print_member(g.members[s]) : print_not_in_group(s)
print_member_today(m::Member) = print_member(m, today())
print_member_today(g::PayGroup, s::String) = haskey(g.members, s) ? print_member_today(g.members[s]) : print_not_in_group(s)

"""
    print_metainfo(g::PayGroup)

Show meta information of a group.
"""
function print_metainfo(g::PayGroup)
    println("Group: \e[91m", g.title, "\e[0m")
    print("Members: \e[36m")
    for name in keys(g.members)
        print(name, " ")
    end
    print("\e[0m\n")
    println("Total: \e[92m", sum(b.total for d in keys(g.bills) for b in values(g.bills[d])), "\e[0m")
    println()
end

"""
    print_bill(bill::Bill)

    Print the information of bills.
"""
function print_bill(b::Bill)
    println("[\e[33m", b.billname, "\e[0m]")
    println("total = \e[31m", b.total, "\e[0m paid by \e[36m", b.paidPy, "\e[0m;")
    if b.isAA
        println("-- \e[34mAA\e[0m --")
    else
        println("-- \e[34mnot AA\e[0m --")
    end
    for (k, v) in b.shouldPay
        println("\e[36m", k, "\e[0m => ", v)
    end
    println()
end
function print_bill(g::PayGroup, d::Date)
    if ! haskey(g.bills, d)
        println("< \e[93m", d, "\e[0m > == \e[32mno bills\e[0m")
        return nothing
    end
    println("< \e[93m", d, "\e[0m > == \e[32m", get_total(g, d), "\e[0m")
    for b in values(g.bills[d])
        print_bill(b)
    end
end
print_bill(g::PayGroup, d) = print_bill(g, Date(d))
"""
    print_bill(g::PayGroup)

Show all the bills in `g::PayGroup`.
"""
function print_bill(g::PayGroup)
    println("\n======\n")
    print_metainfo(g)
    for d in keys(g.bills)
        print_bill(g, d)
        println()
    end
    println("======\n")
end
print_bill(g::PayGroup, s::String, d::Date) = print_bill(g.bills[d][s])
print_bill(g::PayGroup, s::String, d) = print_bill(g, s, Date(d))
print_bill(g::PayGroup, s::String) = print_bill(g, s, today())
print_bill_today(g::PayGroup) = print_bill(g, today())

"""
    show the payment solution.
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

# ------------------------------------ gen ----------------------------------- #
"""
    gen_paygrp() -> payGrp::PayGroup

Generate a `PayGroup` interactively.
"""
function gen_paygrp()
    if isfile("groupay.jld2")
        println("A saved \e[32mPayGroup\e[0m has been detected!")
        println("Do you want to load it?([y]/n)")
        shouldLoad = readline()
        if shouldLoad == "n"
            println("Then let's start a new group.")
        else
            payGrp = load_paygrp("groupay.jld2")
            println("The saved group has been loaded! ^_^")
            payGrp = add_member!(payGrp)
            return payGrp
        end
    end

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


# ------------------------------------ add ----------------------------------- #
"""
    add_member!(x::PayGroup) -> x::PayGroup

    Add more members to a `PayGroup` interactively.
"""
function add_member!(payGrp::PayGroup)
    println("Current members in \e[31m", payGrp.title, "\e[0m:")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
    end
    println("\nDo you want to add more members?([y]/n)")
    shouldAddMem = readline()
    if shouldAddMem == "n"
        return payGrp
    end

    println("\n(\e[31mWarning\e[0m: Repeated names may crash the whole process!)\n")
    println("Who else do you want to add?")
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

    println("\nUpdated members in \e[31m", payGrp.title, "\e[0m:")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
    end

    return payGrp
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

        if ! isempty(payGrp.bills)
            println("And the following bills are added:")
            for (date, dateBills) in payGrp.bills
                println("< \e[93m", date, "\e[0m >")
                for billname in keys(dateBills)
                    println("\e[33m", billname, "\e[0m")
                end
            end
            println()
            println("What's your next bill to add?")
        else
            println("Then let's review your bills together.")
            println()
            println("What's your first bill to add?")
        end

        while true
            # meta info
            billname = readline()
            while isempty(billname)
                println("It's better to give the bill a name, right? ^o^")
                println("So please name your bill:")
                billname = readline()
            end
            bill = Bill(billname, today())

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
            tmpMemHasPaid = payGrp.members[payMan].hasPaid
            if haskey(tmpMemHasPaid, today())
                push!(tmpMemHasPaid[today()], billname => payTotal)
            else
                push!(tmpMemHasPaid, today() => Dict(billname => payTotal))
            end
            bill.total = payTotal
            bill.isAA = true
            bill.paidPy = payMan
            push!(bill.shouldPay, bill.paidPy => bill.total)
            tmpMemShouldPay = payGrp.members[payMan].shouldPay
            if haskey(tmpMemShouldPay, today())
                push!(tmpMemShouldPay[today()], billname => payTotal)
            else
                push!(tmpMemShouldPay, today() => Dict(billname => payTotal))
            end

            if haskey(payGrp.bills, today())
                push!(payGrp.bills[today()], billname => bill)
            else
                push!(payGrp.bills, today() => Dict(billname => bill))
            end

            println()
            print_bill(bill)

            println()
            println("And do you have another bill?([y]/n)")
            hasNextBill = readline()
            if hasNextBill == "n"
                break
            else
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
    if ! isempty(payGrp.bills)
        println("And the following bills are added:")
        for (date, dateBills) in payGrp.bills
            println("< \e[93m", date, "\e[0m >")
            for billname in keys(dateBills)
                println("\e[33m", billname, "\e[0m")
            end
        end
        println()
        println("What's your next bill to add?")
    else
        println("Then let's review your bills together.")
        println()
        println("What's your first bill to add?")
    end

    while true
        # meta info
        billname = readline()
        while isempty(billname)
            println("It's better to give the bill a name, right? ^o^")
            println("So please name your bill:")
            billname = readline()
        end
        bill = Bill(billname, today())

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
        bill.paidPy = payMan

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
        tmpMemHasPaid = payGrp.members[payMan].hasPaid
        if haskey(tmpMemHasPaid, today())
            push!(tmpMemHasPaid[today()], billname => payTotal)
        else
            push!(tmpMemHasPaid, today() => Dict(billname => payTotal))
        end
        bill.total = payTotal

        # details
        println("Do you \e[34mAA\e[0m?([y]/n)")
        isAA = readline()
        if isAA == "n"
            isAA = false
            bill.isAA = isAA

            tmpBill = undef
            while true
                tmpBill = Bill(bill)
                println("How much should each member pay?")
                for name in keys(payGrp.members)
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
                    push!(tmpBill.shouldPay, name => tmpShouldPay)
                end

                if tmpBill.total != sum(values(tmpBill.shouldPay))
                    println()
                    println("Oops! The sum of money doesn't match the total \e[32m", tmpBill.total, "\e[0m!")
                    println("Please input again.")
                else
                    bill = tmpBill
                    break
                end
            end
        else
            isAA = true
            bill.isAA = isAA

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
            avgPay = bill.total / length(AAlist)
            for name in keys(payGrp.members)
                if name in AAlist
                    push!(bill.shouldPay, name => avgPay)
                end
            end
        end
        for (name, val) in bill.shouldPay
            tmpMemShouldPay = payGrp.members[name].shouldPay
            if haskey(tmpMemShouldPay, today())
                push!(tmpMemShouldPay[today()], billname => val)
            else
                push!(tmpMemShouldPay, today() => Dict(billname => val))
            end
        end

        if haskey(payGrp.bills, today())
            push!(payGrp.bills[today()], billname => bill)
        else
            push!(payGrp.bills, today() => Dict(billname => bill))
        end

        println()
        print_bill(bill)

        println()
        println("And do you have another bill?([y]/n)")
        hasNextBill = readline()
        if hasNextBill == "n"
            break
        else
            println()
            println("(\e[32mTip:\e[0m Overwrite \e[32many\e[0m previous bill by inputting the same name.)\n")
            println("What's your next bill?")
        end
    end
    return payGrp
end


function add_bills!(payGrp::PayGroup, inputDate::Date)
    println()

    if length(payGrp.members) == 1
        println("Ok, nice to meet you!")
        payMan = undef
        for x in keys(payGrp.members)
            println("\e[36m", x, "\e[0m")
            payMan = x
        end

        if ! isempty(payGrp.bills)
            println("And the following bills are added:")
            for (date, dateBills) in payGrp.bills
                println("< \e[93m", date, "\e[0m >")
                for billname in keys(dateBills)
                    println("\e[33m", billname, "\e[0m")
                end
            end
            println()
            println("What's your next bill to add?")
        else
            println("Then let's review your bills together.")
            println()
            println("What's your first bill to add?")
        end

        while true
            # meta info
            billname = readline()
            while isempty(billname)
                println("It's better to give the bill a name, right? ^o^")
                println("So please name your bill:")
                billname = readline()
            end
            bill = Bill(billname, today())

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
            tmpMemHasPaid = payGrp.members[payMan].hasPaid
            if haskey(tmpMemHasPaid, today())
                push!(tmpMemHasPaid[today()], billname => payTotal)
            else
                push!(tmpMemHasPaid, today() => Dict(billname => payTotal))
            end
            bill.total = payTotal
            bill.isAA = true
            bill.paidPy = payMan
            push!(bill.shouldPay, bill.paidPy => bill.total)
            tmpMemShouldPay = payGrp.members[payMan].shouldPay
            if haskey(tmpMemShouldPay, today())
                push!(tmpMemShouldPay[today()], billname => payTotal)
            else
                push!(tmpMemShouldPay, today() => Dict(billname => payTotal))
            end

            if haskey(payGrp.bills, today())
                push!(payGrp.bills[today()], billname => bill)
            else
                push!(payGrp.bills, today() => Dict(billname => bill))
            end

            println()
            print_bill(bill)

            println()
            println("And do you have another bill?([y]/n)")
            hasNextBill = readline()
            if hasNextBill == "n"
                break
            else
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
    if ! isempty(payGrp.bills)
        println("And the following bills are added:")
        for (date, dateBills) in payGrp.bills
            println("< \e[93m", date, "\e[0m >")
            for billname in keys(dateBills)
                println("\e[33m", billname, "\e[0m")
            end
        end
        println()
        println("What's your next bill to add?")
    else
        println("Then let's review your bills together.")
        println()
        println("What's your first bill to add?")
    end

    while true
        # meta info
        billname = readline()
        while isempty(billname)
            println("It's better to give the bill a name, right? ^o^")
            println("So please name your bill:")
            billname = readline()
        end
        bill = Bill(billname, today())

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
        bill.paidPy = payMan

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
        tmpMemHasPaid = payGrp.members[payMan].hasPaid
        if haskey(tmpMemHasPaid, today())
            push!(tmpMemHasPaid[today()], billname => payTotal)
        else
            push!(tmpMemHasPaid, today() => Dict(billname => payTotal))
        end
        bill.total = payTotal

        # details
        println("Do you \e[34mAA\e[0m?([y]/n)")
        isAA = readline()
        if isAA == "n"
            isAA = false
            bill.isAA = isAA

            tmpBill = undef
            while true
                tmpBill = Bill(bill)
                println("How much should each member pay?")
                for name in keys(payGrp.members)
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
                    push!(tmpBill.shouldPay, name => tmpShouldPay)
                end

                if tmpBill.total != sum(values(tmpBill.shouldPay))
                    println()
                    println("Oops! The sum of money doesn't match the total \e[32m", tmpBill.total, "\e[0m!")
                    println("Please input again.")
                else
                    bill = tmpBill
                    break
                end
            end
        else
            isAA = true
            bill.isAA = isAA

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
            avgPay = bill.total / length(AAlist)
            for name in keys(payGrp.members)
                if name in AAlist
                    push!(bill.shouldPay, name => avgPay)
                end
            end
        end
        for (name, val) in bill.shouldPay
            tmpMemShouldPay = payGrp.members[name].shouldPay
            if haskey(tmpMemShouldPay, today())
                push!(tmpMemShouldPay[today()], billname => val)
            else
                push!(tmpMemShouldPay, today() => Dict(billname => val))
            end
        end

        if haskey(payGrp.bills, today())
            push!(payGrp.bills[today()], billname => bill)
        else
            push!(payGrp.bills, today() => Dict(billname => bill))
        end

        println()
        print_bill(bill)

        println()
        println("And do you have another bill?([y]/n)")
        hasNextBill = readline()
        if hasNextBill == "n"
            break
        else
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
    for (n, m) in payGrp.members
        tmpToPay = get_topay(m)
        if tmpToPay == 0
            continue
        elseif tmpToPay > 0
            push!(payers, (n, tmpToPay))
        else
            push!(receivers, (n, -tmpToPay))
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
print_soln(x::PayGroup) = print_soln(gen_soln(x))


# ------------------------------------ IO ------------------------------------ #
using JLD2: save_object, load_object
save_paygrp(f::String, g::PayGroup) = save_object(f, g)
save_paygrp(g::PayGroup) = save_paygrp("groupay.jld2", g)
load_paygrp(f::String) = load_object(f)
load_paygrp() = load_paygrp("groupay.jld2")
export save_paygrp, load_paygrp

end # module