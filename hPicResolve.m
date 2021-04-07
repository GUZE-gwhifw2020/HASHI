function mat = hPicResolve()
% HPICRESOLVE 图片解析函数

addpath('./TokenExtract');

load HASHINet.mat net

[ImgSet, mat] = picSlice(imread('0.png'));

matDigit = double(classify(net, ...
    reshape(ImgSet, [size(ImgSet, [1 2]), 1, size(ImgSet, 3)])));

mat(mat > 0) = matDigit;

end