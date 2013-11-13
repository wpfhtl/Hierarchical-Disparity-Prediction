function drawGeneratedMultiLayer
    name = getNames();
    dataSetSize = size(name, 1);
    maxDisp = getMaxDisp();
    level = 2;
    contract = 2;
    maxRange = 1;
    ratio = zeros(level, level,maxRange, 4);
    for i = 1:dataSetSize
        for range = 1:maxRange
            ratio(:, :, range,i) = generateMultiLayer(['data/Prob_Gen_',name{i},'__'], name{i}, maxDisp(i), level, contract, range);
        end
    end
    genRatioHTMLReport(ratio, name, maxDisp, level, 1:maxRange, 'large base 0.5');
    
% 
%     for d = 1:dataSetSize
%         drawRatio_Para(ratio, 1:maxRange, 2,1,d,name);
%     end
end


function ratio = generateMultiLayer(dataset, dataSetName, maxDisp, level, contract, range)
    %     m is the range of disp+1 in layer i
    m = zeros(level);
    for i = 1:level
       m(i) = maxDisp/contract^(i-1)+1;
    end
    
    A = zeros(m(2), m(1),level, level);
    for i = 1:level
        for j = i+1:level
            A(1:m(j), 1:m(i),j,i) = read([dataset,'MST_cnt_',int2str(j-1),'_',int2str(i-1),'.txt'], m(j), m(i));
        end
    end

    smallGivenLarge = zeros(m(2), m(1), level, level);
   	trueLargeGivenSmall = zeros(m(2), m(1), level, level);
    for large = 1:level
        for small = large+1:level
            smallGivenLarge(1:m(small), 1:m(large), small, large) = genLargeBaseSmallGivenLarge(small, large, m(small)-1, m(large)-1, dataSetName);
            trueLargeGivenSmall(1:m(small), 1:m(large), small, large) = findTrueLargeGivenSmall(A(1:m(small), 1:m(large), small, large));
        end
    end

   
    l = getL(m, level, A);
    r = getR(m, level, dataset, smallGivenLarge);
    
    ratio = zeros(level, level);
    for large = 1:level
        for small = large+1:level
            if (small == large+1)
                base = rMul(smallGivenLarge(1:m(small), 1:m(large), small, large),r(1:m(large),large));
            else
                base = smallGivenLarge(1:m(small), 1:m(small-1), small, small-1)*base;
            end
            largeGivenSmall = lMul(getInverse(l(1:m(small),small)), base);
            largeGivenSmall(largeGivenSmall>1) = 1;
            ratio(small,large) = getWrongCoverRatio(largeGivenSmall,...
                                    trueLargeGivenSmall(1:m(small), 1:m(large), small, large), ...
                                    A(1:m(small), 1:m(large), small, large));
            drawAll(A(1:m(small), 1:m(large), small, large),...
                largeGivenSmall,...
                trueLargeGivenSmall(1:m(small), 1:m(large), small, large),...
                smallGivenLarge(1:m(small), 1:m(large), small, large),...
                small, large, dataset, range);
            
%             smallBase = genSmallBase(dataSetName, 2,1);
            largeBase = genLargeBase(dataSetName,2,1);
%             draw2d(-m(small)+1:m(small)-1,smallBase, [dataSetName,'small base']);
            draw2d(-m(large)+1:m(large)-1,largeBase, [dataSetName, ' large base']);
        end
    end
end


% function SL = genSmallGivenLarge(smallDisp, largeDisp, range)
%     SL = zeros(smallDisp+1, largeDisp+1);
%     contract = largeDisp/smallDisp;
%     for j = 0:largeDisp
%         if (rem(j,contract)==0)
%             b = max(0,j/contract-range);
%             t = min(smallDisp, j/contract+range);
%             cnt = t-b+1;
%         else
%             b = max(0, floor(j/contract)-range);
%             t = min(smallDisp, ceil(j/contract)+range);
%             cnt = t-b+1;
%         end
%         for i = b:t
%             SL(i+1,j+1) = 1/cnt;
%         end
%     end
% end

% ------------------------for generation-----------------------------------
function smallGivenLarge = genLargeBaseSmallGivenLarge(small, large, maxSmallDisp, maxLargeDisp, dataSetName)
    smallGivenLarge = readf(['data/gen 0.5/',dataSetName,'__small_given_large_matrix_',int2str(small-1),int2str(large-1),'_large_base.txt'],maxSmallDisp+1, maxLargeDisp+1);
end
function smallGivenLarge = genSmallBaseSmallGivenLarge(small, large, maxSmallDisp, maxLargeDisp, dataSetName)
    smallGivenLarge = readf(['data/gen 0.5/',dataSetName,'__small_given_large_matrix_',int2str(small-1),int2str(large-1),'_small_base.txt'],maxSmallDisp+1, maxLargeDisp+1);
end
function base = genLargeBase(dataSetName, small, large)
%     base = readPd(['data/',dataSetName,'__avg_prob_large_base.txt']);
    base = readPd(['data/gen 0.5/',dataSetName,'__avg_prob_',int2str(small-1), int2str(large-1),'_large_base.txt']);
end
function base = genSmallBase(dataSetName, small, large)
%     base0 = readPd(['data/',dataSetName,'__avg_prob_small_base_even',int2str(small-1), int2str(large-1),'.txt']);
%     base1 = readPd(['data/',dataSetName,'__avg_prob_small_base_odd',int2str(small-1), int2str(large-1),'.txt']);
%     base = [base0,base1];
    base = readPd(['data/gen 0.5/',dataSetName,'__avg_prob_',int2str(small-1), int2str(large-1),'_small_base.txt']);
end
% ------------------------for file read------------------------------------
function l = readPd(filename) 
    file = fopen(filename,'r');
    l = fscanf(file, '%f\n',[1,inf]);
    fclose(file);
    l = l'; 
end
function l = readSupport(filename) 
    file = fopen(filename,'r');
    l = fscanf(file, '%d\n',[1,inf]);
    fclose(file);
    l = l'; l = l/sum(l);
end

function A = read(filename, m, n)
    A = zeros(m, n);
    file = fopen(filename, 'r');
    for i = 1:m
        A(i,:) = fscanf(file, '%d ',[1, n]);
        fscanf(file, '\n');
    end
    fclose(file);
end
function A = readf(filename, m, n)
    A = zeros(m, n);
    file = fopen(filename, 'r');
    for i = 1:m
        A(i,:) = fscanf(file, '%f ',[1, n]);
        fscanf(file, '\n');
    end
    fclose(file);
end
% ----------------------------for calculation------------------------------
function ratio = getWrongCoverRatio(largeGivenSmall, trueLargeGivenSmall, A)
    totalPoints = sum(sum(A));
    wrongPoints = A((largeGivenSmall==0) & (trueLargeGivenSmall ~= 0));
    ratio = sum(wrongPoints)/totalPoints;
end
function r = getR(m, level, dataset, smallGivenLarge)
    r = zeros(m(1), level);
    r(1:m(1),1) = readSupport([dataset,'support_disp_cnt.txt']);
    for i = 2:level-1
        r(1:m(i),i) = smallGivenLarge(1:m(i),1:m(i-1), i,i-1)*r(1:m(i-1),i-1);
    end
end
function l = getL(m ,level, A)
    l = zeros(m(1), level);
%     for i = 1: level
%         l(1:m(i),i) = readPd([dataset, 'MST__pd_',int2str(i-1),'.txt']);
%     end  
%     l(1:m(1),1) = genR(A(1:m(2), 1:m(1), 2,1));
     for i = 2: level
        l(1:m(i),i) = genL(A(1:m(i), 1:m(i-1), i,i-1));
%         draw2d(trueL, ['trueL', int2str(i)]);
%         draw2d(l(1:m(i),i), ['genL', int2str(i)]);
%         draw2d(l(1:m(i),i)-trueL, ['errL', int2str(i)]);
    end
end
function r = genR(A)
    r = sum(A);
    s = sum(r);
    r = r'/s;
end

function l = genL(A)
    l = sum(A, 2);
    s = sum(l);
    l = l/s;
end
function Y = getInverse(L)
    [m, n] = size(L);
    Y = zeros(m,n);
    if n < m 
        n = m;
    end
    for i = 1:n
        if L(i) >= 0.00001
            Y(i) = 1/L(i);
        else Y(i) = 0;
        end
    end
end

% function smallGivenLarge = findSmallGivenLarge(A)
%    [small, large] = size(A);
%     L = sum(A);
%     L = getInverse(L);
%     smallGivenLarge = A.*(ones(small,1)*L);
% end

function largeGivenSmall = findTrueLargeGivenSmall(A)
    [small, large] = size(A);
    s = sum(A, 2);
    s = getInverse(s);
    largeGivenSmall = A.*(s*ones(1,large));
end
function product = lMul(l, A) 
    n = size(A,2);
    product = A.*(l*ones(1,n));
end
function product = rMul(A, r)
    r = r';
    m = size(A,1);
    product = A.*(ones(m,1)*r);
end
% ------------------------------for drawing--------------------------------
function draw2d(x, y, string) 
    figure();
    plot(x, y);title(string);
end

function draw(A, m,n, index, string, equal) 
    [small, large] = size(A);
    subplot(m,n, index);
    [X, Y] = meshgrid(0:large-1, 0:small-1);
    if ~equal
        surf(X,Y, A), shading interp; colorbar; title(string); 
    else
         surf(X,Y, A), shading interp; colorbar; title(string); axis equal;
    end
end
function drawAll(A, largeGivenSmall, trueLargeGivenSmall, smallGivenLarge, small, large, dataset, range)
    small = small-1; large = large-1;
    err = largeGivenSmall-trueLargeGivenSmall;
    
    wrongCover = err;
%     wrongCover(largeGivenSmall<trueLargeGivenSmall & trueLargeGivenSmall>0) = -1;
    wrongCover(largeGivenSmall<trueLargeGivenSmall & largeGivenSmall>0) = ...
        -wrongCover(largeGivenSmall<trueLargeGivenSmall & largeGivenSmall>0);
        
    f = figure();
    [dataset, int2str(f)]
%     draw(A, 1,1,1, ['cnt', int2str(small),int2str(large)], false);
%     figure();
    draw(smallGivenLarge, 4,2,1, [dataset,'smallGivenLarge',int2str(small),int2str(large), 'Range',int2str(range)], false);
    draw(smallGivenLarge, 4,2,2, [dataset,'smallGivenLarge',int2str(small),int2str(large), 'Range',int2str(range)],false);
    draw(trueLargeGivenSmall, 4,2,3, [dataset,'largeGivenSmall',int2str(small),int2str(large), 'Range',int2str(range)],false);
    draw(trueLargeGivenSmall, 4,2,4, [dataset,'largeGivenSmall',int2str(small),int2str(large), 'Range',int2str(range)],false);
    draw(largeGivenSmall, 4,2,5, [dataset,'calculatedLargeGivenSmall',int2str(small),int2str(large), 'Range',int2str(range)],false);
    draw(largeGivenSmall, 4,2,6, [dataset,'calculatedLargeGivenSmall',int2str(small),int2str(large), 'Range',int2str(range)],false);
    draw(err, 4,2,7, [dataset,'error',int2str(small),int2str(large), 'Range', int2str(range)],false);
    draw(err, 4,2,8, [dataset,'error',int2str(small),int2str(large), 'Range',int2str(range)], false);
    figure(); 
    draw(wrongCover, 1,1,1, [dataset, 'wrongCover',int2str(small),int2str(large), 'Range', int2str(range)], false);
%     figure();
%     draw(smallGivenLarge,1,1,1,[dataset,'smallGivenLarge', int2str(small), int2str(large)], true);
end
function drawRatio_Para(ratio, para, small, large, data, name)
    draw2d(para, squeeze(ratio(small, large,:,data)),[name{data}, int2str(small-1),int2str(large-1)]);
end

% -------------------------for HTML----------------------------------------
function genRatioHTMLReport(ratio, name, maxDisp, level, para, nameSpec) 
    paraLen = size(para,2);
    dataSetSize = size(name,1);
    f = fopen(['Uncover Ratio Report ',nameSpec,'.html'],'w');
    fprintf(f,'<!DOCTYPE html>\n<html>\n<body>\n');
    fprintf(f,['<h1>Uncover Ratio Report ',nameSpec,'</h1>\n']);
    fprintf(f,'<table border = "3">\n');
    fprintf(f,'<thead>\n<tr>\n');
    fprintf(f,'<td>parameter</td>\n');
    for i=1:paraLen
        fprintf(f, '<td colspan="%d">%f</td>\n',level-1, para(i));
    end
    fprintf(f,'</tr>\n</thead>\n');
%     tbody
    fprintf(f,'<tbody>\n');
    for d=1:dataSetSize
        if (rem(d,2)==0)
            color = '#e3e3e3';
        else color = 'white';
        end
        fprintf(f,[ '<tr style="background:',color,'">\n<td rowspan="%d">',name{d},'(%d)</td>\n</tr>\n'], level, maxDisp(d));
        for i=2:level
            fprintf(f,['<tr style="background:',color,'">\n']);
            for p=1:paraLen
                for j=1:level-1
                    fprintf(f,'<td>%f</td>\n',ratio(i,j,p,d));
                end
            end
            fprintf(f,'</tr>\n');
        end
        fprintf(f,'</tr>\n');
    end
    fprintf(f,'</tbody>\n');
    fprintf(f,'</table>\n');
    fprintf(f,'</body>\n</html>');
    fclose(f);
end
%-------------------------------data set-----------------------------------
function name = getNames()
% name = {'tsukuba'}
    name = {'cones';'teddy';'tsukuba';'venus'}%;...
%             'Aloe';'Baby1';'Baby2';'Baby3';'Bowling1';'Bowling2';'Cloth1';...
%             'Cloth2';'Cloth3';'Cloth4';'Flowerpots';'Lampshade1';...
%             'Lampshade2';'Midd1';'Midd2';'Monopoly';'Plastic';'Rocks1';...
%             'Rocks2';'Wood1';'Wood2'};
end

function disp = getMaxDisp()
% disp = [16]
    disp = [60,60,16,20]%,...
%             90,100,100,83,96,80,96,86,96,86,...
%             83,86,86,65,71,79,93,91,91,70,84];
end
