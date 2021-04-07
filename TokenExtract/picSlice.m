
function [ImgSet, ImgMat] = picSlice(Img, PIC_SIZE)
%% PICSLICE HASHI图片切割
% ===================================== %
% DATE OF BIRTH:    2021.03.29
% NAME OF FILE:     picSlice
% FILE OF PATH:     /TokenExtract
% FUNC:
%   HASHI图片切割。
% ===================================== %
% Input:
%   Img         三通道图片
%   PIC_SIZE    导出图片集大小，默认21
% Output:
%   ImgSet      图片集矩阵，PIC_SIZE * PIC_SIZE * ValidNum
%   ImgMat      有效位置矩阵，大小height * width
% ===================================== %
%% 数据预处理
if(nargin < 2)
    PIC_SIZE = 21;
end

%% HSV - 色调(H),饱和度(S),明度(V)
[H, ~, ~] = rgb2hsv(Img);

%% 网格确定
% 逐列求和
colSum = mean((H > 0.2), 1); [indC, intvC] = peaksDetect(colSum);
% 逐行求和
rowSum = mean((H > 0.2), 2); [indR, intvR] = peaksDetect(rowSum);

%% 网格切割
height = length(indR);
width = length(indC);

ImgSet = zeros(PIC_SIZE, PIC_SIZE, height * width);

YSpan = arrayfun(@(x) round(indR(x)-intvR/2/2):round(indR(x)+intvR/2/2), 1:height, 'UniformOutput', 0);
XSpan = arrayfun(@(x) round(indC(x)-intvC/2/2):round(indC(x)+intvC/2/2), 1:width, 'UniformOutput', 0);

[X,Y] = meshgrid(1:width, 1:height);

for iter = 1:height * width
    ImgSet(:, :, iter) = 256 - imresize(rgb2gray(Img(YSpan{Y(iter)}, XSpan{X(iter)}, :)), [21 21]);
end
ImgMat = double(reshape(mean(ImgSet,[1 2]), [height width]) > 32);
ImgSet(:,:,~ImgMat) = [];


%%
% figure(1);
% subplot(1,2,1); imshow(Img);
% for ii = 1:length(indC), xline(indC(ii)); end
% for ii = 1:length(indR), yline(indR(ii)); end
% subplot(1,2,2); imagesc(H); colormap gray; colormap;
%%
% figure(2); hold on;
% plot(colSum); scatter(indC, colSum(round(indC)), 'Marker', 'diamond');
% plot(rowSum); scatter(indR, rowSum(round(indR)), 'Marker', 'diamond');

end
%%
function [ind, intv] = peaksDetect(lineSum)
[~, st] = findpeaks(diff(lineSum),'MinPeakHeight',0.25);
[~, ed] = findpeaks(-diff(lineSum),'MinPeakHeight',0.25);

ind = (st + ed) / 2;
intv = mean(diff(ind));

if(std(diff(ind)) > 0.7)
    % 修正
    warning('网格划分出现错误，进行修正。')
    [ind, intv] = peaksDetectRevise(lineSum, ind);
end
end

function [ind, intv] = peaksDetectRevise(lineSum, indOri)
intvS = diff(indOri);
intv = mean(intvS(intvS < 1.5*min(intvS)));
K = round((indOri(end) - indOri(1)) / intv);
ind = linspace(indOri(1), indOri(end), K+1);

if(std(diff(ind)) > 0.7)
    % 修正失败
    error('修正失败。');
end
end


