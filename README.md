# P.E.S.
Point kinetics equation solver for education and research purposes. 

This code implements PKE solver expanding on  Yang Xue, Jevremović Tatjana: "Revisiting the Rosenbrock numerical   solutions of the reactor point kinetics equation with numerous examples",  Nuclear Technology and Radiation Protection 24, p. 3-12, (2009)  doi:10.2298/NTRP0901003Yby adding neutron source and thermal-reactivity feedback.

Link to the article by Xue Yang and Tatjana Jevremovic:
http://www.doiserbia.nb.rs/img/doi/1451-3994/2009/1451-39940901003Y.pdf




Example inputs:

input1 : fast/ constant reactivity of 0.0022/ t = 0 to 10s

input2 : fast/ ramp reactivity of 0.0044t/ t = 0 to 1 s

input3 : thermal/ constant reactivity of -0.00375/ t = 0 to 10s

input_zigzag : thermal/ zigzag reactivity described on page 9 of article/ t = 0 to 10s

input_source1 : fast/ constant reactivity of 0.0022/ 2 seconds of source at 1*10^6 n/s/ t = 1 to 10s

input_source2 : fast/ constant reactivity of 0.0022/ 2 seconds of source at 100 n/s/ t = 1 to 10 s
