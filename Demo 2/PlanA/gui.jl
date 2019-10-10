using Gtk
using PyPlot

win = GtkWindow("2D Direction Finder")
g = GtkGrid()
a = GtkLabel("Transmit and Receive")  # a widget for entering text
#set_gtk_property!(a, :text, )

#Add a GtkCheckButton
b = GtkButton("Start")
c = GtkButton("Exit")
#d = GtkButton("Tester")
#push!(win,b)

# Now let's place these graphical elements into the Grid:
g[1:4,1] = a    # Cartesian coordinates, g[x,y]
g[2,2] = b
#g[2,2] = d # spans both columns
g[3,2] = c
set_gtk_property!(g, :column_homogeneous, true)
set_gtk_property!(g, :column_spacing, 15)  # introduce a 15-pixel gap between columns
push!(win, g)

function plotFig(w)
    ion()

    figure()

    a = zeros(100)
    boolean = true
    k = 1
    for i in 1:100
        a[i] = i
    end

    while boolean
        b = rand(Int, 100) # generate random array
        c = rand(Int, 100) # generate random array
        d = rand(Int, 100) # generate random array
        z = [b,c,d]
        clf() # this clears the current figure for the next
        subplot(311)
        plot(a,b)
        subplot(312)
        plot(a,c)
        subplot(313)
        plot(a,d)
        k = k+1
        if(k==10)
            boolean = false
        end
        # plot(a,c) # this will plot a random array of values
        # plot(a,d) # this will plot a random array of values
        sleep(1) # this will wait for 1 second
    end
end
signal_connect(plotFig, b, "clicked")

#= function plotFig2(w)
    ion()

    figure()

    a = zeros(100)
    boolean = true
    k = 1
    for i in 1:100
        a[i] = i
    end

    while boolean
        b = rand(Int, 100) # generate random array
        c = rand(Int, 100) # generate random array
        d = rand(Int, 100) # generate random array
        z = [b,c,d]
        clf() # this clears the current figure for the next
        subplot(311)
        plot(a,b)
        subplot(312)
        plot(a,c)
        subplot(313)
        plot(a,d)
        k = k+1
        if(k==10)
            boolean = false
        end
        # plot(a,c) # this will plot a random array of values
        # plot(a,d) # this will plot a random array of values
        sleep(1) # this will wait for 1 second
    end
  end
signal_connect(plotFig2, d, "clicked") =#


function exit(w)
    Gtk.destroy(win)
  end
signal_connect(exit, c, "clicked")

# if !isinteractive()
#     d = Condition()
#     signal_connect(win, :destroy) do widget
#         notify(c)
#     end
#     wait(c)
# end

#c = GtkScale(false, 0:10)     # a slider

showall(win)
