classdef HASHI
    %HASHI 逻辑游戏HASHI求解工程
    %   此处显示详细说明
    
    properties(Constant = true, Access = private)
        dirUp       = 1;        % 方向常数:上
        dirDown     = 4;        % 方向常数:下
        dirLeft     = 3;        % 方向常数:左
        dirRight    = 2;        % 方向常数:右
    end
    
    properties(Access = public)
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
        
        % ============= %
        archipCell      % 群岛元组{islNum×1}
        islArchInd      % 岛对应群岛号(islNum×1)
        arUnFinIsl      % 群岛中未确定岛下标(2×islNum)
    end
    
    methods (Access = public)
        function obj = HASHI(inputArg)
            %HASHI 构造此类的实例
            %   Input:
            %       inputArg    token字符串或矩阵或空
            
            if(nargin == 0)
                obj.mat = sparse(hPicResolve());
                [obj.height, obj.width] = size(obj.mat);
            else
                if(ischar(inputArg))
                    % 解析字符串
                    [obj.mat, obj.height, obj.width] = hTokenResolve(inputArg);
                elseif(ismatrix(inputArg))
                    % 矩阵赋值
                    obj.mat = sparse(inputArg);
                    [obj.height, obj.width] = size(inputArg);
                end
            end
            
            % 岛个数与数字
            obj.islNum = nnz(obj.mat);
            obj.islDigit = nonzeros(obj.mat);
            
            % 岛桥关系预处理
            obj = obj.surroundingSearch();
            
            % 求解核心变量初始化
            obj.islCurBri = zeros(4, obj.islNum);
            obj.islUpLBri = 2 * (obj.islSI ~= 0);         % 上限初始为2,仅有岛相连
            obj.islIsFin = false(obj.islNum, 1);
            
            
            % 群岛初始化
            obj.islArchInd = reshape(1:obj.islNum, [], 1);
            obj.archipCell = mat2cell(obj.islArchInd, ones(obj.islNum, 1));
            obj.arUnFinIsl = [1:obj.islNum;zeros(1, obj.islNum)];
            
        end
        
        function obj = Genesis(obj)
            %GENESIS 求解主循环
            for ii = 1:obj.islNum
                obj = obj.archipCheck(ii);
            end
            
            jj = 1;
            while(~all(obj.islIsFin) && jj < 22)
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
        
        function Display(obj, figNum)
            %DISPLAY 绘制结果
            
            if(nargin < 2)
                figNum = 1;
            end
            
            figure(figNum); clf; hold on;
            
            % 调整视角
            view(0, -90);
            
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
                    line(col(indIsl)+[0.07 0.07]*(obj.islCurBri(obj.dirDown, indIsl)-1), [row(indIsl) row(obj.islSI(obj.dirDown, indIsl))] + [0.4 -0.4]);
                    line(col(indIsl)-[0.07 0.07]*(obj.islCurBri(obj.dirDown, indIsl)-1), [row(indIsl) row(obj.islSI(obj.dirDown, indIsl))] + [0.4 -0.4]);
                end
                if(obj.islCurBri(obj.dirRight, indIsl) > 0)
                    line([col(indIsl) col(obj.islSI(obj.dirRight, indIsl))] + [0.4 -0.4], row(indIsl)+[0.07 0.07]*(obj.islCurBri(obj.dirRight, indIsl)-1));
                    line([col(indIsl) col(obj.islSI(obj.dirRight, indIsl))] + [0.4 -0.4], row(indIsl)-[0.07 0.07]*(obj.islCurBri(obj.dirRight, indIsl)-1));
                end
            end
            
            % 岛圆圈
            scatter(col, row, 144, 'Marker', 'o', 'MarkerFaceColor', 'w');
            
            % 岛数字
            charColor = {'#A2142F';'#000000'};
            for indIsl = 1:obj.islNum
                text(col(indIsl), row(indIsl), ...
                    num2str(obj.islDigit(indIsl)), ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'Color', charColor{obj.islIsFin(indIsl)+1});
            end
            
            
            % 网格为正方形
            axis equal;
            axis([0 obj.width+1 0 obj.height+1]);
            
            % 关闭周围轴线
            box off;
            
            % 隐藏坐标轴
            set(gca,'xtick',[]);
            set(gca,'ytick',[]);
            
        end
        
        function Display2(obj)
            %DISPLAY2 绘制岛下标
            figure(2); clf; hold on;
            
            % 调整视角
            view(0, -90);
            
            % 网格线
            for ii = 1:obj.width
                line([ii,ii],[0.5,obj.height+0.5],'Color',[0.9,0.9,0.9]);
            end
            for ii = 1:obj.height
                line([0.5,obj.width+0.5],[ii,ii],'Color',[0.9,0.9,0.9]);
            end
            
            % 岛圆圈
            [row,col] = find(obj.mat);
            scatter(col, row, 144, 'Marker', 'o', 'MarkerFaceColor', 'w');
            
            % 岛数字
            for indIsl = 1:obj.islNum
                text(col(indIsl), row(indIsl), ...
                    num2str(indIsl), ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle');
            end
            
            
            % 网格为正方形
            axis equal;
            axis([0 obj.width+1 0 obj.height+1]);
            
            % 关闭周围轴线
            box off;
            
            % 隐藏坐标轴
            set(gca,'xtick',[]);
            set(gca,'ytick',[]);
            
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
                warning('顶点定位出现问题。可能引发不确定错误。');
            end
            
            % 中心坐标
            % 三个参数，x位置，y位置，点击类型
            clickPos = zeros(obj.islNum * 2, 3);
            % 偏置
            xyBias = [xBound(1) yBound(1)] - [xIntv yIntv];
            
            % 坐标信息
            [row, col] = find(obj.mat);
            clickPos(1:end/2,[1 2]) = [col+0.6 row] .* [xIntv yIntv];
            clickPos(end/2+1:end,[1 2]) = [col row+0.6] .* [xIntv yIntv];
            
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
        
        function SavePuzzle(obj)
            %SAVEPUZZLE 保存题面
            if(~exist('HashiSavedPuzzles.mat', 'file'))
                matSave = cell(1);
                matSave{1} = obj.mat;
                save HashiSavedPuzzles.mat matSave
            else
                load HashiSavedPuzzles.mat matSave
                if(any(cellfun(@(x) isequal(x, obj.mat), matSave(max(1,end-9):end))))
                    warning('检测到重复存储。');
                else
                    matSave{end+1} = obj.mat;
                    save HashiSavedPuzzles.mat matSave
                end
            end
        end
        
        function AddCNNTrainData(obj, IMG_FILE_NAME)
            
            addpath('./TokenExtract');
            
            if(nargin < 2)
                IMG_FILE_NAME = '0.png';
            end
            
            % 图片处理
            [ImgSet, ImgMat] = picSlice(imread(IMG_FILE_NAME));
            
            % 有效图片位置判断
            if(isequal(obj.mat ~= 0, ImgMat))
                if(~exist('HASHIDataSet.mat', 'file'))
                    images = ImgSet;
                    label = nonzeros(obj.mat);
                    save HASHIDataSet.mat images label
                else
                    load HASHIDataSet.mat images label
                    images = cat(3, images, ImgSet);
                    label = [label; nonzeros(obj.mat)];
                    save HASHIDataSet.mat images label
                end
                % 信息提示
                fprintf('\t加入样本数: %d\n\t总样本数: %d\n', ...
                    size(ImgSet, 3), length(label));
                
            else
                warning('图片有效位置矩阵与Token解析结果不一致。图片样本加入失败。');
            end
            rmpath('./TokenExtract');
        end
    end
    
    methods (Access = public)
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
            
            % 旧上下限
            curOld = obj.islCurBri(:, indIsl);
            upLOld = obj.islUpLBri(:, indIsl);
            
            % 核心算法 —— 更新上下限
            curNew = max(obj.islCurBri(:, indIsl), ...
                -sum(obj.islUpLBri(:, indIsl)) + obj.islDigit(indIsl) + obj.islUpLBri(:, indIsl));
            upLNew = min(obj.islUpLBri(:, indIsl), ...
                -sum(obj.islCurBri(:, indIsl)) + obj.islDigit(indIsl) + obj.islCurBri(:, indIsl));
            
            % 是否完成
            obj.islIsFin(indIsl) = isequal(curNew, upLNew);
            
            % 更新上下限
            obj.islCurBri(:, indIsl) = curNew;
            obj.islUpLBri(:, indIsl) = upLNew;
            
            % 更新后四周岛桥修改
            D1 = find(curNew > curOld);
            if(~isempty(D1))
                % 变化下限
                IND = sub2ind([4 obj.islNum], 5-D1, obj.islSI(D1, indIsl));
                obj.islCurBri(IND) = curNew(D1);
            end
            
            D2 = find(upLNew < upLOld);
            if(~isempty(D2))
                % 变化上限
                IND = sub2ind([4 obj.islNum], 5-D2, obj.islSI(D2, indIsl));
                obj.islUpLBri(IND) = upLNew(D2);
            end
            D3 = find(curNew & ~curOld);
            for dirTemp = D3'
                indBri = obj.islSB(dirTemp, indIsl);
                if(dirTemp == obj.dirLeft || dirTemp == obj.dirRight)
                    % 水平桥将覆盖垂直桥
                    indBriOv = find(obj.ovLapMat(indBri, :));
                    if(~isempty(indBriOv))
                        % 上下岛下标
                        obj.islUpLBri(obj.dirDown, obj.briUDIsl(1, indBriOv)) = 0;
                        obj.islUpLBri(obj.dirUp, obj.briUDIsl(2, indBriOv)) = 0;
                    end
                    % 新水平桥建立
                    obj = obj.archipForm(obj.briLRIsl(:, indBri));
                else
                    % 垂直桥将覆盖水平桥
                    indBriOv = find(obj.ovLapMat(:, indBri));
                    if(~isempty(indBriOv))
                        % 左右岛下标
                        obj.islUpLBri(obj.dirRight, obj.briLRIsl(1, indBriOv)) = 0;
                        obj.islUpLBri(obj.dirLeft, obj.briLRIsl(2, indBriOv)) = 0;
                    end
                    % 新垂直桥建立
                    obj = obj.archipForm(obj.briUDIsl(:, indBri));
                end
            end
            % 岛所属群岛为确定位置更新
            % archInd = obj.islArchInd(indIsl);
            obj = obj.archipUnIslRefresh(unique(obj.islArchInd([indIsl;obj.islSI(D1, indIsl)])));
            
            if(1 || ~isempty(D1))
                % 群岛检查
                obj = obj.archipCheck(obj.islArchInd(indIsl));
            end
        end
        
        function obj = archipForm(obj, islInds)
            %ARCHIPFORM 连接两组群岛
            %    Input:
            %       islInds     连接位置两岛下标
            
            archInds = sort(obj.islArchInd(islInds));
            if(archInds(1) ~= archInds(2))
                % 两个不同群岛相连
                % 第二群岛中岛移至第一群岛
                obj.archipCell{archInds(1)} = ...
                    [obj.archipCell{archInds(1)};obj.archipCell{archInds(2)}];
                % 第二群岛中岛群岛号改变
                obj.islArchInd(obj.archipCell{archInds(2)}) = archInds(1);
                % 第二群岛删除
                obj.archipCell{archInds(2)} = [];
            end

        end
        
        function obj = archipCheck(obj, archInd)
            %ARCHIPCHEACK 群岛与周围群岛检查,对于生成闭环的予以删除
            %   Input:
            %       archInd     群岛下标
            
            % 群岛中桥未接满岛下标
            islInd = obj.archipCell{archInd}(~obj.islIsFin(obj.archipCell{archInd}));
            
            % 岛个数判断
            if(length(islInd) == 2)
                % 两个岛是否相连
                dirTemp = find(ismember(obj.islSI(:, islInd(1)), islInd(2)) & ...
                    (obj.islUpLBri(:, islInd(1)) - obj.islCurBri(:, islInd(1))) > 0);
                if(~isempty(dirTemp))
                    
                    K1 = obj.islDigit(islInd(1)) - sum(obj.islCurBri(:, islInd(1)));
                    K2 = obj.islDigit(islInd(2)) - sum(obj.islCurBri(:, islInd(2)));
                    if(K1 == 1 && K2 == 1 && ...
                            (nnz(~cellfun(@isempty, obj.archipCell)) > 2 || ...
                            (nnz(~cellfun(@isempty, obj.archipCell)) == 2 && archInd == 1)))
                        
                        obj.islUpLBri(dirTemp, islInd(1)) = 1;
                        obj.islUpLBri(5-dirTemp, islInd(2)) = 1;
                        
                    end
                end
                
            elseif(length(islInd) == 1)
                % 岛剩余可连桥数
                K = obj.islDigit(islInd) - sum(obj.islCurBri(:, islInd));
                if(K <= 2)
                    % 可连桥方向
                    bri = obj.islUpLBri(1:2, islInd) - obj.islCurBri(1:2, islInd);
                    D = find(bri > 0);
                    for ii = 1:length(D)
                        dirTemp = D(ii);
                        % 可连桥另一端岛下标
                        islSurdInd = obj.islSI(dirTemp, islInd);
                        if(isequal(obj.arUnFinIsl(:, obj.islArchInd(islSurdInd)), [islSurdInd;0]) && ...
                                K == (obj.islDigit(islSurdInd) - sum(obj.islCurBri(:, islSurdInd))) && ...
                                nnz(~cellfun(@isempty, obj.archipCell)) > 2)
                            obj.islUpLBri(dirTemp, islInd) = K - 1;
                            obj.islUpLBri(5-dirTemp, islSurdInd) = K - 1;
                        end
                    end
                end
            end
        end
        
        function obj = archipUnIslRefresh(obj, archInds)
            %ARCHIPUNISLREFRESH 更新群岛未确定岛下标
            for iter = 1:length(archInds)
                archInd = archInds(iter);
                islInd = obj.archipCell{archInd}(~obj.islIsFin(obj.archipCell{archInd}));
                switch(length(islInd))
                    case 1
                        obj.arUnFinIsl(:, archInd) = [islInd;0];
                    case 2
                        obj.arUnFinIsl(:, archInd) = islInd;
                    otherwise
                        obj.arUnFinIsl(:, archInd) = [0;0];
                end
            end
        end
        
    end
end
