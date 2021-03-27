classdef HASHI
    %HASHI 逻辑游戏HASHI求解工程
    %   此处显示详细说明
    
    properties(Constant = true, Access = private)
        dirUp       = 1;        % 方向常数:上
        dirDown     = 4;        % 方向常数:下
        dirLeft     = 3;        % 方向常数:左
        dirRight    = 2;        % 方向常数:右
    end
    
    properties(Access = private)
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
    
    methods (Access = public)
        function obj = HASHI(inputArg)
            %HASHI 构造此类的实例
            %   Input:
            %       inputArg    token字符串或矩阵
            
            if(ischar(inputArg))
                % 解析字符串
                [obj.mat, obj.height, obj.width] = hTokenResolve(inputArg);
            elseif(ismatrix(inputArg))
                % 矩阵赋值
                obj.mat = sparse(inputArg);
                [obj.height, obj.width] = size(inputArg);
            end
            
            % 岛个数与数字
            obj.islNum = nnz(obj.mat);
            obj.islDigit = nonzeros(obj.mat);
            
            % 预处理
            obj = obj.surroundingSearch();
            
            % 求解核心变量初始化
            obj.islCurBri = zeros(4, obj.islNum);
            obj.islUpLBri = 2 * (obj.islSI ~= 0);         % 上限初始为2,仅有岛相连
            obj.islIsFin = false(obj.islNum, 1);
        end
        
        function obj = Genesis(obj)
            %GENESIS 求解主循环
            jj = 1;
            while(~all(obj.islIsFin) && jj < 10)
                % 岛遍历
                for indIsl = 1:obj.islNum
                    if(~obj.islIsFin(indIsl))
                        % 岛处理: 更新四边上下界、是否完成
                        obj = obj.islandExcu(indIsl);
                    end
                end
                jj = jj + 1;
            end
        end
        
        function Display(obj)
            %DISPLAY 绘制结果
            figure(1); clf; hold on;
            % 网格线
            for ii = 1:obj.width
                line([ii,ii],[0.5,obj.height+0.5],'Color',[0.9,0.9,0.9]);
            end
            for ii = 1:obj.height
                line([0.5,obj.width+0.5],[ii,ii],'Color',[0.9,0.9,0.9]);
            end
            
            % 岛间桥
            [row,col] = find(obj.mat);
            for indIsl = 1:obj.islNum
                if(obj.islCurBri(obj.dirDown, indIsl) > 0)
                    line(col(indIsl)+[0.1 0.1]*(obj.islCurBri(obj.dirDown, indIsl)-1), [row(indIsl) row(obj.islSI(obj.dirDown, indIsl))]);
                    line(col(indIsl)-[0.1 0.1]*(obj.islCurBri(obj.dirDown, indIsl)-1), [row(indIsl) row(obj.islSI(obj.dirDown, indIsl))]);
                end
                if(obj.islCurBri(obj.dirRight, indIsl) > 0)
                    line([col(indIsl) col(obj.islSI(obj.dirRight, indIsl))], row(indIsl)+[0.1 0.1]*(obj.islCurBri(obj.dirRight, indIsl)-1));
                    line([col(indIsl) col(obj.islSI(obj.dirRight, indIsl))], row(indIsl)-[0.1 0.1]*(obj.islCurBri(obj.dirRight, indIsl)-1));
                end
            end
            
            % 岛圆圈
            scatter(col, row, 144, 'Marker', 'o', 'MarkerFaceColor', 'w');
            
            % 岛数字
            for indIsl = 1:obj.islNum
                text(col(indIsl), row(indIsl), ...
                    num2str(obj.islDigit(indIsl)), ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle');
            end
            
            % 调整视角
            view(0, -90);
            
            % 网格为正方形
            axis equal;
            axis([0 obj.width+1 0 obj.height+1]);
            
            % 关闭周围轴线
            box off
            
            % 隐藏坐标轴
            set(gca,'xtick',[])
            set(gca,'ytick',[])
            
        end
        
        function MouseSimulate(obj)
            %MOUSESIMULATE 模拟鼠标操作
            
            % 运行py文件，获取四顶点坐标
            system('Apex4.py');
            
            % 读取四顶点坐标
            load temp.mat apex
            
            % 导出点击坐标
            % 屏幕像素显示比例
            screenPixelRatio = 2.5;
            
            % 左右像素边界
            apex = sort(apex);
            xBound = round(mean(reshape(apex(:,1), [2 2])));
            yBound = round(mean(reshape(apex(:,2), [2 2])));
            % 单位间隔
            xIntv = diff(xBound) / (obj.width - 1);
            yIntv = diff(yBound) / (obj.height - 1);
            
            if(round(xIntv) ~= round(yIntv))
                warning('顶点定位出现问题。可能引发不确定错误。')
            end
            
            % 中心坐标
            % 三个参数，x位置，y位置，点击类型
            clickPos = zeros(obj.islNum * 2, 3);
            % 偏置
            xyBias = [xBound(1) yBound(1)] - [xIntv yIntv];
            
            % 坐标信息
            [row, col] = find(obj.mat);
            clickPos(1:end/2,[1 2]) = [col+0.75 row] .* [xIntv yIntv];
            clickPos(end/2+1:end,[1 2]) = [col row+0.75] .* [xIntv yIntv];
            
            % 添加总偏置与250%缩放(因电脑而异)
            clickPos(:,1:2) = round((clickPos(:,1:2) + xyBias) / screenPixelRatio);
            
            % 点击属性设置
            clickPos(1:end/2,3) = obj.islCurBri(obj.dirRight, :);
            clickPos(end/2+1:end,3) = obj.islCurBri(obj.dirDown, :);
            
            % 写入
            save('temp.mat','clickPos','-append');
            
            % 执行PY文件模拟点击
            system('Click.py');
            
            % 删除MAT文件
            delete('temp.mat');
        end
        
    end
    
    methods (Access = private)
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
                    obj.islSB(obj.dirRight, iLeft) = obj.briLRNum;
                    obj.islSB(obj.dirLeft, iRight) = obj.briLRNum;
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
        
        function obj = islandExcu(obj, indIsl)
            %ISLANDEXCU 岛处理
            %   Input:
            %       indIsl      岛下标
            
            % 核心算法 —— 更新上下限
            curNew = max(obj.islCurBri(:, indIsl), ...
                -sum(obj.islUpLBri(:, indIsl)) + obj.islDigit(indIsl) + obj.islUpLBri(:, indIsl));
            upLNew = min(obj.islUpLBri(:, indIsl), ...
                -sum(obj.islCurBri(:, indIsl)) + obj.islDigit(indIsl) + obj.islCurBri(:, indIsl));
            
            % 是否完成
            obj.islIsFin(indIsl) = isequal(curNew, upLNew);
            
            % 更新后四周岛桥修改
            D = find(curNew > obj.islCurBri(:, indIsl));
            if(~isempty(D))
                % 变化下限
                IND = sub2ind([4 obj.islNum], 5-D, obj.islSI(D, indIsl));
                obj.islCurBri(IND) = curNew(D);
            end
            D = find(upLNew < obj.islUpLBri(:, indIsl));
            if(~isempty(D))
                % 变化上限
                IND = sub2ind([4 obj.islNum], 5-D, obj.islSI(D, indIsl));
                obj.islUpLBri(IND) = upLNew(D);
            end
            D = find(curNew & ~obj.islCurBri(:, indIsl));
            for dirTemp = D'
                indBri = obj.islSB(dirTemp, indIsl);
                if(dirTemp == obj.dirLeft || dirTemp == obj.dirRight)
                    % 水平桥将覆盖垂直桥
                    indBriOv = find(obj.ovLapMat(indBri, :));
                    if(~isempty(indBriOv))
                        % 上下岛下标
                        islIndUP = obj.briUDIsl(:, indBriOv);
                        obj.islUpLBri(obj.dirDown, islIndUP(1, :)) = 0;
                        obj.islUpLBri(obj.dirUp, islIndUP(2, :)) = 0;
                    end
                else
                    % 垂直桥将覆盖水平桥
                    indBriOv = find(obj.ovLapMat(:, indBri));
                    if(~isempty(indBriOv))
                        % 左右岛下标
                        islIndLR = obj.briLRIsl(:, indBriOv);
                        obj.islUpLBri(obj.dirRight, islIndLR(1, :)) = 0;
                        obj.islUpLBri(obj.dirLeft, islIndLR(2, :)) = 0;
                    end
                end
            end
                        
            % 更新上下限
            obj.islCurBri(:, indIsl) = curNew;
            obj.islUpLBri(:, indIsl) = upLNew;
        end
        
    end

end

