## Gossip and Push Sum Protocol
	
## Project compiled by
	Akash Jajoo
	Niraj Chowdhary

## Steps to execute
1.  Open the command prompt and type **mix run proj2.exs numNodes topology algorithm** 
  Here,
     **numNodes** is the number of actors involved
      **topology** is one of the following- full, line, rand2D, 3D torus, honeycomb or random honeycomb
      **algorithm** is either gossip or push-sum.  
    **Output:**  Time taken to converge in milliseconds.
    
 
## Gossip Algorithm
The Gossip algorithm involves the following: 
* **Starting**: A participant (actor) is told/sent a rumor (fact) by the main process
* **Step**: Each actor selects a random neighbor and tells it the rumor
* **Termination**: Each actor keeps track of rumors and how many times it has heard the rumor. It stops transmitting once it has heard the rumor 10 times

## Push Sum Algorithm
* In push-sum algorithm, every actor maintains two quantities s and w, initially, s = xi = i and w=1 for all nodes.

* Messages sent and received are pairs of the form (s, w). Upon receive, an actor adds received pair to its own corresponding values. Upon receive, each actor selects a random neighbour and sends it a message.

* Messages sent and received are pairs of the form (s, w). Upon receive, an actor should add received pair to its own corresponding values. Upon receive, each actor selects a random neighbour and sends it a message**.**

* Messages sent and received are pairs of the form (s, w). Upon receive, an actor should add received pair to its own corresponding values. Upon receive, each actor selects a random neighbour and sends it a message.

* Messages sent and received are pairs of the form (s, w). Upon receive, an actor should add received pair to its own corresponding values. Upon receive, each actor selects a random neighbour and sends it a message.

## Interesting findings
* In gossip algorithm, when the no. of nodes is less than 100 then all the algorithms converge in similar time except Rand2D which does not converge at all because of its randomness.

* As no. of nodes increases, line and Rand2D take more time to converge as compared to other topologies.
* 3D torus is the best topology in gossip algorithm.
* Full topology is also very good in gossip algorithm but it is the worst in push-sum algorithm.

* Honeycomb is the best algorithm when no. of nodes is high for push-sum algorithm.
* RandHoneycomb and Honeycomb do not vary in performance by a lot as only 1 random node is connected to the topology.

## Graphs
[![Screenshot-26.png](https://i.postimg.cc/Qd80dN5n/Screenshot-26.png)](https://postimg.cc/mtnQdsmQ)

[![Screenshot-27.png](https://i.postimg.cc/hjWmhM6P/Screenshot-27.png)](https://postimg.cc/cKhCb7dV)