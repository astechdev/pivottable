callWithJQuery = (pivotModule) ->
    if typeof exports is "object" and typeof module is "object" # CommonJS
        pivotModule require("jquery")
    else if typeof define is "function" and define.amd # AMD
        define ["jquery"], pivotModule
    # Plain browser env
    else
        pivotModule jQuery
        
callWithJQuery ($) ->

    $.pivotUtilities.datatables_renderers = "Datatable": (pivotData, opts) ->
        defaults =
            localeStrings:
                totals: "Totals"

        opts = $.extend defaults, opts

        colAttrs = pivotData.colAttrs
        rowAttrs = pivotData.rowAttrs
        rowKeys = pivotData.getRowKeys()
        colKeys = pivotData.getColKeys()

        #now actually build the output
        result = document.createElement("table")
        result.className = "pvtTable"
        thead = document.createElement("thead");
        tbody = document.createElement("tbody");
        tfoot = document.createElement("tfoot");

        #helper function for setting row/col-span in pivotTableRenderer
        spanSize = (arr, i, j) ->
            if i != 0
                noDraw = true
                for x in [0..j]
                    if arr[i-1][x] != arr[i][x]
                        noDraw = false
                if noDraw
                  return -1 #do not draw cell
            len = 0
            while i+len < arr.length
                stop = false
                for x in [0..j]
                    stop = true if arr[i][x] != arr[i+len][x]
                break if stop
                len++
            return len

        #the first few rows are for col headers
        for own j, c of colAttrs
            tr = document.createElement("tr")
            if parseInt(j) == 0 and rowAttrs.length != 0
                th = document.createElement("th")
                th.setAttribute("colspan", rowAttrs.length)
                th.setAttribute("rowspan", colAttrs.length)
                tr.appendChild th
            th = document.createElement("th")
            th.className = "pvtAxisLabel"
            th.innerHTML = c
            tr.appendChild th
            for own i, colKey of colKeys
                x = spanSize(colKeys, parseInt(i), parseInt(j))
                if x != -1
                    th = document.createElement("th")
                    th.className = "pvtColLabel"
                    th.innerHTML = colKey[j]
                    th.setAttribute("colspan", x)
                    if parseInt(j) == colAttrs.length-1 and rowAttrs.length != 0
                        th.setAttribute("rowspan", 2)
                    tr.appendChild th
            if parseInt(j) == 0
                th = document.createElement("th")
                th.className = "pvtTotalLabel"
                th.innerHTML = opts.localeStrings.totals
                th.setAttribute("rowspan", colAttrs.length + (if rowAttrs.length ==0 then 0 else 1))
                tr.appendChild th
            thead.appendChild tr

        #then a row for row header headers
        if rowAttrs.length !=0
            tr = document.createElement("tr")
            for own i, r of rowAttrs
                th = document.createElement("th")
                th.className = "pvtAxisLabel"
                th.innerHTML = r
                tr.appendChild th 
            th = document.createElement("th")
            if colAttrs.length ==0
                th.className = "pvtTotalLabel"
                th.innerHTML = opts.localeStrings.totals
            tr.appendChild th
            thead.appendChild tr

        #now the actual data rows, with their row headers and totals
        for own i, rowKey of rowKeys
            tr = document.createElement("tr")
            for own j, txt of rowKey
                th = document.createElement('th')
                th.className = 'pvtRowLabel'
                th.innerHTML = txt
                tr.appendChild th
                if parseInt(j) == rowAttrs.length-1 and colAttrs.length !=0
                    tr.appendChild document.createElement('th')
            for own j, colKey of colKeys #this is the tight loop
                aggregator = pivotData.getAggregator(rowKey, colKey)
                val = aggregator.value()
                td = document.createElement("td")
                td.className = "pvtVal row#{i} col#{j}"
                td.innerHTML = aggregator.format(val)
                td.setAttribute("data-value", val)
                tr.appendChild td

            totalAggregator = pivotData.getAggregator(rowKey, [])
            val = totalAggregator.value()
            td = document.createElement("td")
            td.className = "pvtTotal rowTotal"
            td.innerHTML = totalAggregator.format(val)
            td.setAttribute("data-value", val)
            td.setAttribute("data-for", "row"+i)
            tr.appendChild td
            tbody.appendChild tr

        #finally, the row for col totals, and a grand total
        tr = document.createElement("tr")
        th = document.createElement("th")
        th.className = "pvtTotalLabel"
        th.innerHTML = opts.localeStrings.totals
        th.setAttribute("colspan", rowAttrs.length + (if colAttrs.length == 0 then 0 else 1))
        tr.appendChild th
        for own j, colKey of colKeys
            totalAggregator = pivotData.getAggregator([], colKey)
            val = totalAggregator.value()
            td = document.createElement("td")
            td.className = "pvtTotal colTotal"
            td.innerHTML = totalAggregator.format(val)
            td.setAttribute("data-value", val)
            td.setAttribute("data-for", "col"+j)
            tr.appendChild td
        totalAggregator = pivotData.getAggregator([], [])
        val = totalAggregator.value()
        td = document.createElement('td')
        td.className = 'pvtGrandTotal'
        td.innerHTML = totalAggregator.format(val)
        td.setAttribute("data-value", val)
        tr.appendChild td
        result.appendChild thead
        result.appendChild tbody
        tfoot.appendChild tr
        result.appendChild tfoot

        #squirrel this away for later
        result.setAttribute("data-numrows", rowKeys.length)
        result.setAttribute("data-numcols", colKeys.length)

        return result
    
