# HeatTransferOptimization

This was the project that started it all.  A couple years ago in my heat transfer course we were tasked with designing an optimal convective heatsink for a simple 2D heat transfer problem.  As part of the assignment, we were allowed to incorporate simulations from the software package of our choosing into our analysis.  Most other students relied on off-the-shelf solutions like Solidworks Simulation or ANSYS, but naturally I got carried away and decided to implement my own in MATLAB.  By writing my own simulation, I was able to use simulated annealing to evolve an optimal heat sink geometry.

Here is the original problem statement:
![Problem statement](https://raw.githubusercontent.com/chrisstroemel/HeatTransferOptimization/master/Screenshot%20from%202016-03-10%2021%3A13%3A36.png)

The first thing you'll notice about this problem is that the object we need to simulate is fairly blocky.  Since we don't need to worry as much about conforming to some intricate geometry, we can do away with finite elements and instead use [finite differences](https://en.wikipedia.org/wiki/Finite_difference_method) which are much less of a pain to implement.  This involves breaking up the heat transfer PDE into individual energy balances across a grid superimposed onto the part.  This turns the PDE into a system of linear equations that allow us to easily solve for temperature based on the heat transfer boundary conditions.

This is what the simulation results look like:
![Results](https://github.com/chrisstroemel/HeatTransferOptimization/blob/master/Screenshot%20from%202016-03-31%2023:36:36.png)

Unoccupied surroundings are depicted as dark blue.  This really old screenshot isn't labelled with proper units, but the color bar represents temperature in degrees C.  Looking at the results, a few things stand out right away.  The copper core and aluminum heat sink both have fairly uniform temperature, which makes sense since these materials have high thermal conductivity.  There is also a region of high temperature near the insulated bottom of the part, which also makes sense.

So at this point we spent a while writing code to do something that we could have done in a few minutes in ANSYS, but now let's do something interesting.  
