%% Birth Certificate
% ===================================== %
% DATE OF BIRTH:    2021.03.27
% NAME OF FILE:     hACase
% FILE OF PATH:     /HASHI
% FUNC:
%   HASHI类实例
% ===================================== %
% clc

%%
strToken = input('    输入Token:','s');

%%
if(~isempty(strToken))
    X = HASHI(strToken);
else
    X = HASHI();
end

%%
X = X.Genesis();

%%
X.Display();
X.SavePuzzle();