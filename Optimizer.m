elementsPerCm = 20
maxIterations = 20
createIrregularFins = false
withEqualSpacing = true
solidTop = true
informationInterval = 100

kCopper = 386
kSteel = 17
kAluminum = 180
h = 50
tAmbient = 20
dx = 0.01 / elementsPerCm
dimension = 2 + (5 * elementsPerCm);
finLength = 0.01
heatGenPerSquareCm = 1 / (0.004 * finLength)
heatGenPerElement = heatGenPerSquareCm / (elementsPerCm ^ 2)



%making the conductivity matrix:
if (solidTop)
    topLayer = kAluminum .* ones(1 * elementsPerCm, 5 * elementsPerCm);
else
    topLayer = zeros(1 * elementsPerCm, 5 * elementsPerCm);
end
aluminumLayer = kAluminum .* ones(1 * elementsPerCm, 5 * elementsPerCm);
steelLayer = kSteel .* ones(1 * elementsPerCm, 5 * elementsPerCm);
steelSegment = kSteel .* ones(1 * elementsPerCm, 2 * elementsPerCm);
copperSegment = kCopper .* ones(1 * elementsPerCm, 1 * elementsPerCm);

conductivityMatrix = [topLayer; aluminumLayer; steelLayer; steelSegment copperSegment steelSegment; steelLayer];
%now adding the surrounding air:
conductivityMatrix = [zeros(5 * elementsPerCm, 1) conductivityMatrix zeros(5 * elementsPerCm, 1)];
conductivityMatrix = [zeros(1, (5 * elementsPerCm) + 2); conductivityMatrix; zeros(1, (5 * elementsPerCm) + 2)];

%making the heat generation matrix:
top = zeros(1 + (3 * elementsPerCm), 2 + (5 * elementsPerCm));
segment = zeros(1 * elementsPerCm, 1 + (2 * elementsPerCm));
copperHeatGen = heatGenPerElement .* (ones(1 * elementsPerCm, 1 * elementsPerCm));
bottom = zeros(1 + (1 * elementsPerCm), 2 + (5 * elementsPerCm));

heatGenMatrix = [top; segment copperHeatGen segment; bottom];

%compute geometry matrix (0 for air, 1 for solid):
geometryMatrix = not(not(conductivityMatrix));

%precompute surface exposure matrix and update later as needed:
nMatrix = zeros(2 + (5 * elementsPerCm), 2 + (5 * elementsPerCm));
for y = 2:(5 * elementsPerCm)
    for x = 2:(5 * elementsPerCm)
        nMatrix(y, x) = not(geometryMatrix(y + 1, x)) + not(geometryMatrix(y - 1, x)) + not(geometryMatrix(y, x + 1)) + not(geometryMatrix(y, x - 1));
    end
end
%insulate the bottom
nMatrix(1 + (5 * elementsPerCm), : ) = zeros(1, 2 + (5 * elementsPerCm));



% everything else before was just setting up the problem
% now the real fun can begin (shape optimization!)
bestConductivityMatrix = conductivityMatrix;
bestGeometryMatrix = geometryMatrix;
bestExposureMatrix = nMatrix;
bestCoreTemp = 10000; % initially high so that the solution can progress
bestTempMatrix = zeros(dimension);
minTemperatures = zeros(1, maxIterations);


%begin the optimization loop
for iteration = 1:maxIterations

    %monitor progress
    if (mod(iteration, informationInterval) == 0)
        iteration
        iteration / maxIterations
    end
    

    if (createIrregularFins)
        mutating = true;
        while mutating
            
            conductivityMatrix = bestConductivityMatrix;
            geometryMatrix = bestGeometryMatrix;
            nMatrix = bestExposureMatrix;


            %generate a random mutation of the geometry
            xCoord = 1 + ceil(5 * elementsPerCm * rand());
            yCoord = 1 + ceil(1 * elementsPerCm * rand());
            currentState = geometryMatrix(yCoord, xCoord);


            %update model state with the new mutation so it can be tested
            newState = not(currentState); %toggle from solid to air, or vice-versa
            conductivityMatrix(yCoord, xCoord) = newState * kAluminum;
            geometryMatrix(yCoord, xCoord) = newState;
            dN = (2 * currentState) - 1;
            nMatrix(yCoord + 1, xCoord) = nMatrix(yCoord + 1, xCoord) + dN;
            nMatrix(yCoord - 1, xCoord) = nMatrix(yCoord - 1, xCoord) + dN;
            nMatrix(yCoord, xCoord + 1) = nMatrix(yCoord, xCoord + 1) + dN;
            nMatrix(yCoord, xCoord - 1) = nMatrix(yCoord, xCoord - 1) + dN;

            %check if the mutation produces a void


            fullySurrounded = geometryMatrix(yCoord + 1, xCoord) + geometryMatrix(yCoord - 1, xCoord) + geometryMatrix(yCoord, xCoord + 1) + geometryMatrix(yCoord, xCoord - 1);

            validSurroundings = true;
            if (newState == 1 && fullySurrounded == 0)
                validSurroundings = false;
            elseif (newState == 0 && fullySurrounded == 4)
                validSurroundings = false;
            end


            if (validSurroundings)
                topIsValid = isValid(yCoord - 1, xCoord, geometryMatrix, elementsPerCm);
                bottomIsValid = isValid(yCoord + 1, xCoord, geometryMatrix, elementsPerCm);
                leftIsValid = isValid(yCoord, xCoord - 1, geometryMatrix, elementsPerCm);
                rightIsValid = isValid(yCoord, xCoord + 1, geometryMatrix, elementsPerCm);

                mutating = not(topIsValid && bottomIsValid && leftIsValid && rightIsValid);
            else
                mutating = true;
            end
        end
    else
        conductivityMatrix = bestConductivityMatrix;
        geometryMatrix = bestGeometryMatrix;
        nMatrix = bestExposureMatrix;
        if (withEqualSpacing)
            finIndex = 2;
            generateFin = true;
            while (finIndex < dimension)
                for step = 1:iteration
                    xCoord = finIndex;
                    yCoord = 2;
                    if xCoord < (dimension - 1)
                        currentState = geometryMatrix(yCoord, xCoord);
                        if (currentState ~= generateFin)
                            for yCoord = 2:(1 + (1 * elementsPerCm))
                                %update model state with the new mutation so it can be tested
                                newState = not(currentState); %toggle from solid to air, or vice-versa
                                conductivityMatrix(yCoord, xCoord) = newState * kAluminum;
                                geometryMatrix(yCoord, xCoord) = newState;
                                dN = (2 * currentState) - 1;
                                nMatrix(yCoord + 1, xCoord) = nMatrix(yCoord + 1, xCoord) + dN;
                                nMatrix(yCoord - 1, xCoord) = nMatrix(yCoord - 1, xCoord) + dN;
                                nMatrix(yCoord, xCoord + 1) = nMatrix(yCoord, xCoord + 1) + dN;
                                nMatrix(yCoord, xCoord - 1) = nMatrix(yCoord, xCoord - 1) + dN;
                            end
                        end
                    end
                    if step == iteration
                        generateFin = not(generateFin);
                    end
                    finIndex = finIndex + 1;
                end
            end
        else
            %generate a random mutation of the geometry
            xCoord = 1 + ceil(5 * elementsPerCm * rand());
            yCoord = 2;
            currentState = geometryMatrix(yCoord, xCoord);

            for yCoord = 2:(1 + (1 * elementsPerCm))
                %update model state with the new mutation so it can be tested
                newState = not(currentState); %toggle from solid to air, or vice-versa
                conductivityMatrix(yCoord, xCoord) = newState * kAluminum;
                geometryMatrix(yCoord, xCoord) = newState;
                dN = (2 * currentState) - 1;
                nMatrix(yCoord + 1, xCoord) = nMatrix(yCoord + 1, xCoord) + dN;
                nMatrix(yCoord - 1, xCoord) = nMatrix(yCoord - 1, xCoord) + dN;
                nMatrix(yCoord, xCoord + 1) = nMatrix(yCoord, xCoord + 1) + dN;
                nMatrix(yCoord, xCoord - 1) = nMatrix(yCoord, xCoord - 1) + dN;
            end
        end
    end







    %%MESH ASSEMBLY
    relationMatrix = zeros(dimension .^ 2);
    heatGenAndLossVector = zeros(dimension .^ 2, 1);
    for y = 1:dimension
        for x = 1:dimension
            if (y ~= 1) && (y ~= dimension) && (x ~= 1) && (x ~= dimension)
                index = ((y - 1) * dimension) + x;
                n = nMatrix(y, x);
                emptinessFactor = geometryMatrix(y, x);
                kU = conductivityMatrix(y - 1, x);
                kD = conductivityMatrix(y + 1, x);
                kL = conductivityMatrix(y, x - 1);
                kR = conductivityMatrix(y, x + 1);
                %create entry for this element
                relationMatrix(index, index) = emptinessFactor * -1 * ((n .* h) + ((1 ./ dx) * (kU + kD + kL + kR)));
                %create entries for the surrounding elements
                relationMatrix(index, index - dimension) = kU * emptinessFactor / dx;
                relationMatrix(index, index + dimension) = kD * emptinessFactor / dx;
                relationMatrix(index, index - 1) = kL * emptinessFactor / dx;
                relationMatrix(index, index + 1) = kR * emptinessFactor / dx;

                %make entry in heat transfer vector
                heatGenAndLossVector(index) = emptinessFactor * -1 * ((n * h * tAmbient) + heatGenMatrix(y, x));
            end
        end
    end

    %solving for temperatures
    %remove zero columns and rows

    [zeroRows, zeroColumns] = find(not(diag(relationMatrix)));
    [nonZeroRows, nonZeroColumns] = find(diag(relationMatrix));
    relationMatrix(zeroRows, : ) = [];
    relationMatrix(:, zeroRows) = [];
    length(heatGenAndLossVector);
    heatGenAndLossVector(zeroRows) = [];
    length(heatGenAndLossVector);
    

    numElements = dimension ^ 2;
    indexesRemoved = (numElements + 1) .* ones(numElements, 1);
    currentRemoveIndex = 1;
    
    % solve
    tempVector = relationMatrix \ heatGenAndLossVector;
    
   %reinflating the temperature vector
    resultVector = zeros(1, numElements);
    resultVector(nonZeroRows) = tempVector;
    
    %put back in matrix form
    tempMatrix = reshape(resultVector, dimension, dimension);


    %compute fitness
    maxTemp = max(tempVector);
    minTemperatures(iteration) = maxTemp;
    

    %if this mutation is more fit than the last version, keep the changes
    if maxTemp < bestCoreTemp
        bestConductivityMatrix = conductivityMatrix;
        bestGeometryMatrix = geometryMatrix;
        bestExposureMatrix = nMatrix;
        bestTempMatrix = tempMatrix;
        bestCoreTemp = maxTemp;
    end
    
end

%plot result
bestCoreTemp
displayTempMatrix = transpose(bestTempMatrix);
displayTempMatrix(displayTempMatrix == 0) = 20; % adjusts temp scale for display
imagesc(displayTempMatrix)
colorbar

if (withEqualSpacing && not(createIrregularFins))
    numFins = (dimension - 2) ./ (1:1:maxIterations);
    xAxis = numFins;
else
   xAxis = (1:1:maxIterations);
end
figure
plot(xAxis, minTemperatures)
ylabel('Max Core Temp. (Celcius)')
xlabel('Number of Fins')
