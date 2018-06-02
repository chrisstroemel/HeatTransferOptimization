
function [valid] = isValid(y, x, geometryMatrix, elementsPerCm)
    valid = true;
    hasMoved = false;
    bonusMove = false;
    graceSteps = 5;
    remainingSteps = elementsPerCm ^ 2;
    if (geometryMatrix(y, x) == 0)
        direction = 1;
        xPos = x;
        yPos = y;
        maxDimension = 2 + (5 * elementsPerCm);
        while (yPos ~= 1)
            if direction == 1
                fBlocked = geometryMatrix(yPos - 1, xPos) == 1;
                if (xPos == maxDimension)
                    rBlocked = true;
                else
                    rBlocked = geometryMatrix(yPos, xPos + 1) == 1;
                end
                if (xPos == 1)
                    lBlocked = true;
                else
                    lBlocked = geometryMatrix(yPos, xPos - 1) == 1;
                end
            elseif direction == 2
                if (xPos == 1)
                    fBlocked = true;
                else
                    fBlocked = geometryMatrix(yPos, xPos - 1) == 1;
                end
                rBlocked = geometryMatrix(yPos - 1, xPos) == 1;
                if (yPos == maxDimension)
                    lBlocked = true;
                else
                    lBlocked = geometryMatrix(yPos + 1, xPos) == 1;
                end
            elseif direction == 3
                if (yPos == maxDimension)
                    fBlocked = true;
                else
                    fBlocked = geometryMatrix(yPos + 1, xPos) == 1;
                end
                rBlocked = geometryMatrix(yPos, xPos - 1) == 1;
                if (xPos == maxDimension)
                    lBlocked = true;
                else
                    lBlocked = geometryMatrix(yPos, xPos + 1) == 1;
                end
            else
                if (xPos == maxDimension)
                    fBlocked = true;
                else
                    fBlocked = geometryMatrix(yPos, xPos + 1) == 1;
                end
                rBlocked = geometryMatrix(yPos + 1, xPos) == 1;
                lBlocked = geometryMatrix(yPos - 1, xPos) == 1;
            end

            %behavior
             if  ~hasMoved && (graceSteps == 0)
                valid = false;
                return;
             elseif (remainingSteps == 0)
                valid = false;
                return;
             elseif (yPos == 1)
                return
            elseif (xPos == x) && (yPos == y) && (graceSteps == 0 || hasMoved == true)
                valid = false;
                yPos = 1;
                return
            elseif ((direction == 1) || rBlocked || bonusMove) && not(fBlocked)
                %move forward
                if (direction == 1)
                    yPos = yPos - 1;
                elseif (direction == 2)
                    xPos = xPos - 1;
                elseif (direction == 3)
                    yPos = yPos + 1;
                else
                    xPos = xPos + 1;
                end
                hasMoved = true;
            elseif not(rBlocked)
                %% turn right
                if (direction == 1)
                    direction = 4;
                else
                    direction = direction - 1;
                end
                bonusMove = not(lBlocked);
            else
                %turn left
                if (direction == 4)
                    direction = 1;
                else
                    direction = direction + 1;
                end
            end
            if (~hasMoved)
               graceSteps = graceSteps - 1;
            end
            remainingSteps = remainingSteps - 1;
        end

    end

end

