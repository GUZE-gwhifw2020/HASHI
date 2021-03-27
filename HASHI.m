classdef HASHI
    %HASHI 逻辑游戏HASHI求解工程
    %   此处显示详细说明
    
    properties(Constant)
        dirUp       = 1;        % 方向常数:上
        dirDown     = 4;        % 方向常数:下
        dirLeft     = 3;        % 方向常数:左
        dirRight    = 2;        % 方向常数:右
        
        
    end
    
    properties
        % ============= %
        width           % 宽度，列个数
        height          % 高度，行个数
        
        mat             % 题面矩阵
        
        islNum          % 岛个数
        islDigit        % 岛连接桥个数(1×islNum)
        islSI           % 岛四周岛序号(4×islNum)
        islSB           % 岛四周桥序号(4×islNum)
        
        briUDNum        % 垂直桥个数
        briLRNum        % 水平桥个数
        briUDIsl        % 垂直桥两端岛下标(2×briUDNum)(Up-Down)
        briLRIsl        % 水平桥两端岛下标(2×briLRNum)(Left-Right)
        ovLapMat        % 重叠矩阵(briLRNum×briUDNum)
        
        % ============= %
        islCurBri       % 岛当前桥连接数(4×islNum)
        islUpLBri       % 岛当前上限桥数(4×islNum)
        islIsFin        % 岛是否完成(1×islNum)
        
    end
    
    methods
        function obj = HASHI(tokStrArg)
            %HASHI 构造此类的实例
            %   Input:
            %       tokStrArg   token字符串
            
            % 解析字符串
            [obj.mat, obj.height, obj.width] = hTokenResolve(tokStrArg);
            
            % 岛个数与数字
            obj.islNum = nnz(obj.mat);
            obj.islDigit = nonzeros(obj.mat);
            
            % 预处理
            obj = obj.surroundingSearch();
        end
        
        function obj = surroundingSearch(obj)
            %SURROUNDINGSEARCH 四周初始化
            % Task1. 初始化islSI
            % Task2. 寻找briUDNum, briLRNum
            % Task3. 确定islSB
            % Task4. 确定briUDIsl, briLRIsl
            % Task5. 确定ovLapMat
            
            obj.briLRNum = 0; obj.briUDIsl = zeros(2, obj.islNum);
            obj.briUDNum = 0; obj.briLRIsl = zeros(2, obj.islNum);
            obj.islSB = zeros(4,obj.islNum);
            obj.islSI = zeros(4,obj.islNum);
            
            % 辅助变量: mat中非零位置行列数
            [row, col] = find(obj.mat);
            
            % 上下关系
            for ii = 2:obj.islNum
                if(col(ii-1) == col(ii))
                    % 岛周围岛号赋值
                    obj.islSI(obj.dirUp, ii) = ii - 1;
                    obj.islSI(obj.dirDown, ii - 1) = ii;
                    % 上下桥数递增
                    obj.briUDNum = obj.briUDNum + 1;
                    % 桥两端岛号赋值
                    obj.briUDIsl(:, obj.briUDNum) = [ii-1;ii];
                    % 岛四周桥号赋值
                    obj.islSB(obj.dirUp, ii) = obj.briUDNum;
                    obj.islSB(obj.dirDown, ii-1) = obj.briUDNum;
                end
            end
            [~, I] = sort(row);
            for ii = 2:obj.islNum
                iLeft = I(ii-1); iRight = I(ii);
                if(row(iLeft) == row(iRight))
                    % 岛周围岛号赋值
                    obj.islSI(obj.dirLeft, iRight) = iLeft;
                    obj.islSI(obj.dirRight, iLeft) = iRight;
                    % 上下桥数递增
                    obj.briLRNum = obj.briLRNum + 1;
                    % 桥两端岛号赋值
                    obj.briLRIsl(:, obj.briLRNum) = [iLeft;iRight];
                    % 岛四周桥号赋值
                    obj.islSB(obj.dirRight, iLeft) = obj.briUDNum;
                    obj.islSB(obj.dirLeft, iRight) = obj.briUDNum;
                end
            end
            
            % 收缩
            obj.briUDIsl = obj.briUDIsl(:, 1:obj.briUDNum);
            obj.briLRIsl = obj.briLRIsl(:, 1:obj.briLRNum);
            
            % 桥重叠
            obj.ovLapMat = sparse(zeros(obj.briLRNum, obj.briUDNum));
            % 桥当前行数/列数
            briLRRow = row(obj.briLRIsl(1,:));
            briUDCol = col(obj.briUDIsl(1,:));
            % 桥跨度（起始行/列数）
            briLRSpan = [col(obj.briLRIsl(1,:)) col(obj.briLRIsl(2,:))];
            briUDSpan = [row(obj.briUDIsl(1,:)) row(obj.briUDIsl(2,:))];
            for ii = 1:obj.briUDNum
                obj.ovLapMat(:, ii) = ...
                    briLRSpan(:, 1) < briUDCol(ii) & ...
                    briLRSpan(:, 2) > briUDCol(ii) & ...
                    briUDSpan(ii, 1) < briLRRow & ...
                    briUDSpan(ii, 2) > briLRRow;
            end
            
        end
        
        
        function Genesis(obj)
            %GENESIS 求解主循环
            
        end
        
        function Display(obj)
            %DISPLAY 绘制结果
            %   此处显示详细说明
            
        end
        
        function MouseSimulate(obj)
            %MOUSESIMULATE 模拟鼠标操作
        end


    end
end

