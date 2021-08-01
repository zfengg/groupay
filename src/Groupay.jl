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
export main_groupay, cmd_flow, gen_paygrp, add_bills!, add_member!
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
    flagShouldPay = haskey(m.shouldPay, d)

    if (!flagHasPaid) && (!flagShouldPay)
        return nothing
    end
    println("< \e[93m", d, "\e[0m >")

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

print_not_in_group(s::String) = println("Sorry, \e[36m", s, "\e[0m is not in your group!")

print_member(g::PayGroup, s::String, d::Date) = haskey(g.members, s) ? print_member(g.members[s], d) : print_not_in_group(s)
print_member(g::PayGroup, s::String, d) = print_member(g::PayGroup, s, Date(d))
print_member(g::PayGroup, s::String) = haskey(g.members, s) ? print_member(g.members[s]) : print_not_in_group(s)

print_member_today(m::Member) = print_member(m, today())
print_member_today(g::PayGroup, s::String) = haskey(g.members, s) ? print_member_today(g.members[s]) : print_not_in_group(s)
function print_member_today(g::PayGroup)
    for m in values(g.members)
        print_member_today(m)
    end
end

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
    if ! isempty(g.bills)
        println("Total: \e[92m", sum(b.total for d in keys(g.bills) for b in values(g.bills[d])), "\e[0m")
    end
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
function print_bill(g::PayGroup, s::String, d::Date)
    if ! haskey(g.bills, d)
        println("< \e[93m", d, "\e[0m > has no bills!")
        return nothing
    end
    if ! haskey(g.bills[d], s)
        println("< \e[93m", d, "\e[0m > has no bill: \e[33m", s, "\e[0m !")
        return nothing
    end
    print_bill(g.bills[d][s])
end
print_bill(g::PayGroup, s::String, d) = print_bill(g, s, Date(d))
print_bill_today(g::PayGroup) = print_bill(g, today())
print_bill_today(g::PayGroup, s::String) = print_bill(g, s, today())

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
    println()
    println("Current members in \e[31m", payGrp.title, "\e[0m:")
    for x in keys(payGrp.members)
        println("\e[36m", x, "\e[0m")
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
    add_bills!(payGrp::PayGroup, insertDate::Date) -> payGrp::PayGroup

    Add bills on `insertDate` to `payGrp`.
"""
function add_bills!(payGrp::PayGroup, insertDate::Date)
    isToday = isequal(insertDate, today())
    println()

    if length(payGrp.members) == 1
        println("Ok, nice to meet you!")
        payMan = undef
        for x in keys(payGrp.members)
            println("\e[36m", x, "\e[0m")
            payMan = x
        end

        if ! isempty(payGrp.bills)
            println("And you have added the following bills:")
            for (date, dateBills) in payGrp.bills
                println("< \e[93m", date, "\e[0m >")
                for billname in keys(dateBills)
                    println("\e[33m", billname, "\e[0m")
                end
            end
            println()
            println("What's your next bill to add for < \e[93m", isToday ? "today" : insertDate, "\e[0m >?")
        else
            println("Then let's review your bills together.")
            println()
            println("What's your first bill to add for < \e[93m", isToday ? "today" : insertDate, "\e[0m >?")
        end

        while true
            # meta info
            billname = readline()
            while isempty(billname)
                println("It's better to give the bill a name, right? ^o^")
                println("So please name your bill:")
                billname = readline()
            end
            if haskey(payGrp.bills, insertDate) && haskey(payGrp.bills[insertDate], billname)
                for m in values(payGrp.members)
                    if haskey(m.hasPaid, insertDate) && haskey(m.hasPaid[insertDate], billname)
                        pop!(m.hasPaid[insertDate], billname)
                        if isempty(m.hasPaid[insertDate])
                            pop!(m.hasPaid, insertDate)
                        end
                    end
                    if haskey(m.shouldPay, insertDate) && haskey(m.shouldPay[insertDate], billname)
                        pop!(m.shouldPay[insertDate], billname)
                        if isempty(m.shouldPay[insertDate])
                            pop!(m.shouldPay, insertDate)
                        end
                    end
                end
            end
            bill = Bill(billname, insertDate)

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
            if haskey(tmpMemHasPaid, insertDate)
                push!(tmpMemHasPaid[insertDate], billname => payTotal)
            else
                push!(tmpMemHasPaid, insertDate => Dict(billname => payTotal))
            end
            bill.total = payTotal
            bill.isAA = true
            bill.paidPy = payMan
            push!(bill.shouldPay, bill.paidPy => bill.total)
            tmpMemShouldPay = payGrp.members[payMan].shouldPay
            if haskey(tmpMemShouldPay, insertDate)
                push!(tmpMemShouldPay[insertDate], billname => payTotal)
            else
                push!(tmpMemShouldPay, insertDate => Dict(billname => payTotal))
            end

            if haskey(payGrp.bills, insertDate)
                push!(payGrp.bills[insertDate], billname => bill)
            else
                push!(payGrp.bills, insertDate => Dict(billname => bill))
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
        println("And you have added the following bills:")
        for (date, dateBills) in payGrp.bills
            println("< \e[93m", date, "\e[0m >")
            for billname in keys(dateBills)
                println("\e[33m", billname, "\e[0m")
            end
        end
        println()
        println("What's your next bill to add for \e[93m", isToday ? "today" : insertDate, "\e[0m ?")
    else
        println("Then let's review your bills together.")
        println()
        println("What's your first bill to add for < \e[93m", isToday ? "today" : insertDate, "\e[0m >?")
    end

    while true
        # meta info
        billname = readline()
        while isempty(billname)
            println("It's better to give the bill a name, right? ^o^")
            println("So please name your bill:")
            billname = readline()
        end
        if haskey(payGrp.bills, insertDate) && haskey(payGrp.bills[insertDate], billname)
            for m in values(payGrp.members)
                if haskey(m.hasPaid, insertDate) && haskey(m.hasPaid[insertDate], billname)
                    pop!(m.hasPaid[insertDate], billname)
                    if isempty(m.hasPaid[insertDate])
                        pop!(m.hasPaid, insertDate)
                    end
                end
                if haskey(m.shouldPay, insertDate) && haskey(m.shouldPay[insertDate], billname)
                    pop!(m.shouldPay[insertDate], billname)
                if isempty(m.shouldPay[insertDate])
                        pop!(m.shouldPay, insertDate)
                    end
                end
            end
        end
        bill = Bill(billname, insertDate)

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
        if haskey(tmpMemHasPaid, insertDate)
            push!(tmpMemHasPaid[insertDate], billname => payTotal)
        else
            push!(tmpMemHasPaid, insertDate => Dict(billname => payTotal))
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
            for name in AAlist
                push!(bill.shouldPay, name => avgPay)
            end
        end

        for (name, val) in bill.shouldPay
            tmpMemShouldPay = payGrp.members[name].shouldPay
            if haskey(tmpMemShouldPay, insertDate)
                push!(tmpMemShouldPay[insertDate], billname => val)
            else
                push!(tmpMemShouldPay, insertDate => Dict(billname => val))
            end
        end

        if haskey(payGrp.bills, insertDate)
            push!(payGrp.bills[insertDate], billname => bill)
        else
            push!(payGrp.bills, insertDate => Dict(billname => bill))
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
add_bills!(g::PayGroup, d) = add_bills!(g, Date(d))
add_bills!(g::PayGroup) = add_bills!(g, today())


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

# ----------------------------- interactive usage ---------------------------- #
manual = [
    ["g", "show meta-info of your group"],
    ["s", "show payment solution"],
    ["b", "show all bills"],
    ["b foo", "show bill named by \e[33mfoo\e[0m"],
    ["bt", "show only \e[93mtoday\e[0m's bills"],
    ["bt foo", "show \e[93mtoday\e[0m's bill named by \e[33mfoo\e[0m"],
    ["m", "show bills of all members"],
    ["m bar", "show all the bills of \e[36mbar\e[0m"],
    ["m bar 2021-8-1", "show bills of \e[36mbar\e[0m on \e[93m2021-8-1\e[0m"],
    ["mt", "show \e[93mtoday\e[0m's bills for each member"],
    ["mt bar", "show only \e[93mtoday\e[0m's bills of \e[36mbar\e[0m "],
    ["am", "add members"],
    ["ab", "add bills \e[93mtoday\e[0m"],
    ["ab 2008-8-8", "add bills on \e[93m2008-8-8\e[0m"],
    ["sg", "save your group"],
    ["lg", "load your group"],
    ["dg", "delete your group"]
]

function print_man_element(cmd)
    println("  \e[32m", cmd[1], "\e[0m : ", cmd[2])
end

function print_manual(man)
    println("\e[35mCommand manual\e[0m:")
    print_man_element.(man)
    println("Get help by \e[32mh\e[0m; quit by \e[31mq\e[0m\n")
end
print_manual() = print_manual(manual)

print_invalidcmd() = println("\e[31mInvalid\e[0m command! Please input again.")
function exec_cmd(g::PayGroup, nextCmd)
    nextCmd = split(nextCmd)
    nextCmd = String.(nextCmd)
    if isempty(nextCmd)
        print_invalidcmd()
        return false
    end

    headCmd = nextCmd[1]
    lenCmd = length(nextCmd)
    if headCmd == "q"
        return true
    elseif headCmd == "h"
        print_manual()
    elseif headCmd == "g"
        print_metainfo(g)
    elseif headCmd == "s"
        print_soln(g)
    elseif headCmd == "b"
        if lenCmd >= 3
            try
                print_bill(g, nextCmd[2], nextCmd[3])
            catch
                print_invalidcmd()
            end
        elseif lenCmd >= 2
            print_bill(g, nextCmd[2])
        else
            print_bill(g)
        end
    elseif headCmd == "bt"
        if lenCmd >= 2
            print_bill_today(g, nextCmd[2])
        else
            print_bill_today(g)
        end
    elseif headCmd == "m"
        if lenCmd >= 3
            try
                print_member(g, nextCmd[2], nextCmd[3])
            catch
                print_invalidcmd()
            end
        elseif lenCmd >= 2
            print_member(g, nextCmd[2])
        else
            print_member(g)
        end
    elseif headCmd == "mt"
        if lenCmd >= 2
            print_member_today(g, nextCmd[2])
        else
            print_member_today(g)
        end
    elseif headCmd == "am"
        add_member!(g)
    elseif headCmd == "ab"
        if lenCmd >= 2
            try
                add_bills!(g, nextCmd[2])
            catch
                print_invalidcmd()
            end
        else
            add_bills!(g)
        end
    elseif headCmd == "sg"
        save_paygrp(g)
        println("Group saved!")
    elseif headCmd == "lg"
        load_paygrp("groupay.jld2")
    elseif headCmd == "dg"
        rm("groupay.jld2")
        println("\e[31mgroupap.jl\e[0m deleted!")
    else
        print_invalidcmd()
    end
    return false
end

"""
execute commands recursively
"""
function cmd_flow(g::PayGroup)
    print_manual()
    shouldExit = false
    while ! shouldExit
        println("What's next? (\e[32mh\e[0m to help; \e[31mq\e[0m to quit)")
        nextCmd = readline()
        println()
        shouldExit = exec_cmd(g, nextCmd)
        println()
    end
end

function main_groupay()
    # greetings
    run(`clear`)
    println("Hi, there! Welcome to happy ~\e[32m group pay \e[0m~")
    println("We will provide you a payment solution for your group.")
    # check saved group
    println()
    if isfile("groupay.jld2")
        println("A saved group at \e[32mgroupay.jld2\e[0m has been detected!")
        println("Do you want to load it?([y]/n)")
        shouldLoad = readline()
        if shouldLoad == "n"
            println("Then let's start a new group.")
            # generate group
            println()
            payGrp = gen_paygrp()
        else
            payGrp = load_paygrp("groupay.jld2")
            println()
            println("The saved group has been loaded! ^_^")
            print_metainfo(payGrp)
            # enter cmd flow
            println("\nDo you want to enter command mode directly?([y]/n)")
            willContinue = readline()
            if willContinue != "n"
                cmd_flow(payGrp)
                println("\nHave a good day ~")
                return payGrp
            end
            # interactive mode
            println("Do you want to add more members?(y/[n])")
            shouldAddMem = readline()
            if shouldAddMem == "y"
                payGrp = add_member!(payGrp)
            end
            println()
            println("And you have added the following bills:")
            for (d, dateBills) in payGrp.bills
                println("< \e[93m", d, "\e[0m >")
                for billname in keys(dateBills)
                    println("\e[33m", billname, "\e[0m")
                end
            end
        end
    else
        # generate group
        println()
        payGrp = gen_paygrp()
    end
    # add bills
    println("\nDo you want to add some bills?([y]/n)")
    shouldAddBill = readline()
    if shouldAddBill == "n"
        println("\nHave a good day ~")
        return payGrp
    end
    println("And on today?([y]/n)")
    onToday = readline()
    if onToday == "n"
        while true
            println("So on which date? e.g., 2021-8-12")
            insertDate = readline()
            try
                add_bills!(payGrp, insertDate)
                break
            catch
                println("Wrong date format!")
            end
        end
    else
        payGrp = add_bills!(payGrp)
    end
    # payment solution
    print_soln(payGrp)
    # save
    println("\nDo you want to save your group?([y]/n)")
    ynFlag = readline()
    if ynFlag == "n"
    else
        save_paygrp(payGrp)
        println("Group saved as \e[32mgroupay.jld2\e[0m ^_^")
    end
    # show info
    println("\nShow detailed information?(y/[n])")
    willContinue = readline()
    if willContinue != "y"
        println()
        println("Have a good day ~")
        exit()
    end
    # print bills
    println("\nShow all the bills?([y]/n)")
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
    # cmd flow
    println("\nDo you want to enter command mode?(y/[n])")
    willContinue = readline()
    if willContinue != "y"
        println()
        println("Have a good day ~")
        exit()
    end
    cmd_flow(payGrp)
    println()
    println("Have a good day ~")
    return payGrp
end

end # module