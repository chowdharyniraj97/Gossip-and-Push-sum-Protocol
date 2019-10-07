defmodule Proj2 do
	def start do
		n=String.to_integer(Enum.at(System.argv(),0))
		topology=Enum.at(System.argv(),1)
		algorithm=Enum.at(System.argv(),2)
		if (algorithm == "gossip") do
			case topology do
				"full" -> Full.fire(n,topology)
	      "line" -> Line.fire(n,topology)
	      "rand2D" -> Twod.fire(n,topology)
				"3Dtorus" -> Threed.fire(n,topology)
				"honeycomb" -> Honeycomb.fire(n,topology)
				"randhoneycomb" -> Honeycomb.fire(n,topology)
			end
		else
			case topology do
				"full" -> Pfull.fire(n,topology)
	      "line" -> Pline.fire(n,topology)
	      "rand2D" -> Ptwod.fire(n,topology)
				"3Dtorus" -> Pthreed.fire(n,topology)
				"honeycomb" -> Phoneycomb.fire(n,topology)
				"randhoneycomb" -> Phoneycomb.fire(n,topology)
			end
		end
	end
end

Proj2.start
