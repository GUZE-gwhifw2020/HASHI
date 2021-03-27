function [mat, height, width] = hTokenResolve(tokStr)
%HTOKENRESOLVE Hashi逻辑游戏token字符串解析函数

% Input:
%   tokStr  : token字符串

% Output:
%   mat     : 题面矩阵(稀疏矩阵)
%   height  : 高度，行个数
%   width   : 宽度，列个数

% Example:

% tokStr = '4d2c3a3b3q3a1g2a4c1';

% mat = [4 0 0 0 0 2 0;
%       0 0 3 0 3 0 0;
%       3 0 0 0 0 0 0;
%       0 0 0 0 0 0 0;
%       0 0 0 0 3 0 1;
%       2 0 4 0 0 0 1;
%       ];

% mat = 
%         (1,1)        4
%         (3,1)        3
%         (7,1)        2
%         (2,3)        3
%         (7,3)        4
%         (2,5)        3
%         (5,5)        3
%         (1,6)        2
%         (5,7)        1
%         (7,7)        1
   
% Note: 
%   1. tokStr中可能出现多个字母连续情况
%   2. 初始零元素与结束零元素均已用字母表示

% 拆分字符串
[digitC, characterC] = regexp(tokStr,'[1-8]','match','split');

% 提取岛数字
digI = str2double(digitC);

% 提取岛间隔
funcS = @(x) sum(abs(x) - 96);
intv = cellfun(funcS, characterC);

% 计算岛坐标
loc = cumsum(intv) + (1:length(intv));

% 计算行列大小
matNumel = loc(end) - 1;
[height, width] = sizeDefine(matNumel);

% 题面矩阵赋值
mat = sparse(zeros(width, height));     % 后续转置后大小正常
mat(loc(1:end-1)) = digI;
mat = transpose(mat);

end

%%
function [height, width] = sizeDefine(matNumel)
%SIZEDEFINE 依据题面总大小确定行列数
if(ismember(matNumel, [49 100 225 625 900]))
    height = sqrt(matNumel);
    width = sqrt(matNumel);
elseif(matNumel == 1200)
    width = 30;
    height = 40;
elseif(matNumel == 2000)
    width = 40;
    height = 50;
else
    error('Error: 无法确定行列数大小');
end
end