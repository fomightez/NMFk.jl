# loading librarires
using NMF
using Clustering
using Distances
using Stats

# setting directory and adjusting params
cd("/home/boian/Desktop/NMF_2014/Julia/");
globalIter = 10; # nNMF; number of NMF's
nmfIter = 100000; # number of NMF interations
numberOfProcesses = 2; # nk

# reading input file and initilizing arrays
inputMatrix = readdlm("input/input.txt", '\t');
numberOfPoints   = size(inputMatrix, 1); # nT; number of observations for each point
numberOfSamples = size(inputMatrix, 2);  # nP; number of observation points (number of observation records)

allProcesses = zeros( numberOfPoints, numberOfProcesses, globalIter ); # HBig; here it is transposed ( nT, nk, nNMF )
allMixtures  = zeros( numberOfProcesses, numberOfSamples, globalIter ); # WBig; here it is transposed ( nk, nP, nNMF )

# nonnegative matrix factorization over multiple iterations
for curentIteration = 1 : globalIter
	processes, mixtures = NMF.randinit( inputMatrix, numberOfProcesses, normalize = true);
	NMF.solve!(NMF.MultUpdate( obj = :mse, maxiter = nmfIter ), inputMatrix, processes, mixtures);
	for j = 1 : numberOfProcesses # additional normalization
		total = sum( processes[:, j] );
		processes[:, j] = processes[:, j] ./ total;
		mixtures[j, :]  = mixtures[j, :] .* total;
	end
	allProcesses[:, :, curentIteration] = processes; # filin globalIter
	allMixtures[:, :, curentIteration] = mixtures;   # filin globalIter
	println("NMF iteration $(curentIteration)/$(globalIter) has completed!");
end

# clustering extracted processes
clusterRepeatMax = 10000;
idx = zeros(numberOfProcesses, globalIter);
centroids = allProcesses[:, :, 1];
idx = zeros(Int, numberOfProcesses, globalIter);

for clusterIt = 1 : clusterRepeatMax
	for globalIterID = 1 : globalIter
		processesTaken = zeros(numberOfProcesses , 1);
		centroidsTaken = zeros(numberOfProcesses , 1);
		for currentProcessID = 1 : 	numberOfProcesses
			distMatrix = ones(numberOfProcesses, numberOfProcesses) * 100; 
			for processID = 1 : numberOfProcesses
				for centroidID = 1 : numberOfProcesses
					if ( (centroidsTaken[centroidID] == 0) && ( processesTaken[processID] == 0) )
						distMatrix[processID, centroidID] = cosine_dist(allProcesses[:, processID, globalIterID], centroids[:,centroidID]);
					end
				end
			end
			minProcess,minCentroid = ind2sub(size(distMatrix), indmin(distMatrix));
			processesTaken[minProcess] = 1;
			centroidsTaken[minCentroid] = 1;
			idx[minProcess, globalIterID] = minCentroid;
		end

	end
	centroids = zeros( numberOfPoints, numberOfProcesses );
	for centroidID = 1 : numberOfProcesses
		for globalIterID = 1 : globalIter
			centroids[:, centroidID] = centroids[:, centroidID] + allProcesses[:, findin(idx[:,globalIter], centroidID), globalIter];
		end
	end
	centroids = centroids ./ globalIter;
end

# calculating stability of final processes and mixtures
idx_r = vec(reshape(idx, numberOfProcesses * globalIter, 1));
allProcesses_r = reshape(allProcesses, numberOfPoints, numberOfProcesses * globalIter);
allMixtures_r = reshape(allMixtures, numberOfProcesses * globalIter, numberOfSamples);
allProcessesDist = pairwise(CosineDist(), allProcesses_r);
stabilityProcesses = silhouettes( idx_r, vec(repmat([globalIter], numberOfProcesses, 1)), allProcessesDist);

avgStabilityProcesses = zeros(numberOfProcesses, 1);
processes = zeros(numberOfPoints, numberOfProcesses);
mixtures = zeros( numberOfProcesses, numberOfSamples);

for i = 1 : numberOfProcesses
	avgStabilityProcesses[i] = mean(stabilityProcesses[ findin(idx_r,i) ]);
	processes[:, i] = centroids[:, i];
	mixtures[i, :] = mean( allMixtures_r[ findin(idx_r,i),: ] )
end

dataRecon = processes * mixtures;

dataReconCorr = zeros(numberOfSamples, 1);

for i = 1 : numberOfSamples
	dataReconCorr[i] = cor( inputMatrix[:,i], dataRecon[:, i] );
end
