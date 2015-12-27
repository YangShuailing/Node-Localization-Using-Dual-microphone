clc;
clear all  %清除 
close all; %关闭之前数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%%%%  初始化数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
Size_Grid=10;  %房间大小，单位：m 
Length = Size_Grid; %% 房间的长度，单位：m 
Width = Size_Grid;  %% 房间的宽度，单位：m 
Microphone_Distance = 0.5; %手机上两个mic之间距离 （m)
r = Microphone_Distance/2;
Point_Step = 0.01;% 空间粒度
Node_Number = 4; %节点个数
Anchor_Number = 3; % 锚节点个数
Node_all = Node_Number+Anchor_Number;
p_band=0.1;%%MSP：不考虑保护带
% min_bound = 0.1;  %% LP的上下界，缺失将不能工作
% max_bound = 10;
RUNS = 1; %%仿真次数
Scan_Time = 6; %%扫描次数
% cita=-90+180*(rand(1,Acoustic_Number));  %%朝向 [-90  90]  %%% 精度和声源个数有关系
angle = [];
normal_min = 1;
normal_max=10;
normal_gap=1;
%%%%%%%生成麦克风位置朝向信息
Microphone_Cita=fix(360*(rand(Node_Number,1)));  %%朝向 [0 360] 以x正半轴与麦克风1的夹角上    
% Microphone_Cita = [0 90 180 270];
Microphone_Center_Location=fix(Size_Grid*abs(rand(Node_Number,2))); % 中心 位置
% Microphone_Center_Location = [2 8; 8 2;2 2; 8 8];
% Anchor_Location = fix(Size_Grid*abs(rand(Anchor_Number,2)));  % 锚节点坐标
Anchor_Location =[4 5; 5 4; 5 5];
Anchor_Cita = [45 90 135];
% Anchor_Cita=fix(-90+180*(rand(Anchor_Number,1)));  %%锚节点朝向 [-90  90]  
Acoustic_Loc = Microphone_Center_Location ; % 声源位置
Microphone_1_Location=zeros(Node_Number,2); % 顶部 位置
Microphone_2_Location=zeros(Node_Number,2); % 底部 位置

for  i=1:Node_Number
%%(L/2,0)
Microphone_1_Location(i,1)=Microphone_Center_Location(i,1) + 0.5*Microphone_Distance*(cos(Microphone_Cita(i)*pi/180));
Microphone_1_Location(i,2)=Microphone_Center_Location(i,2) + 0.5*Microphone_Distance*(-sin(Microphone_Cita(i)*pi/180));  
 %%(-L/2,0)
Microphone_2_Location(i,1)=Microphone_Center_Location(i,1) - 0.5*Microphone_Distance*(cos(Microphone_Cita(i)*pi/180));
Microphone_2_Location(i,2)=Microphone_Center_Location(i,2) - 0.5*Microphone_Distance*(-sin(Microphone_Cita(i)*pi/180));        
end
for  i=1:Anchor_Number
%%(L/2,0)
Anchor_Microphone_1_Location(i,1)=Anchor_Location(i,1) + 0.5*Microphone_Distance*(cos(Anchor_Cita(i)*pi/180));
Anchor_Microphone_1_Location(i,2)=Anchor_Location(i,2) + 0.5*Microphone_Distance*(-sin(Anchor_Cita(i)*pi/180));  
 %%(-L/2,0)
Anchor_Microphone_2_Location(i,1)=Anchor_Location(i,1) - 0.5*Microphone_Distance*(cos(Anchor_Cita(i)*pi/180));
Anchor_Microphone_2_Location(i,2)=Anchor_Location(i,2) - 0.5*Microphone_Distance*(-sin(Anchor_Cita(i)*pi/180));        
end
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 画出节点位置
figure('Position',[1 1 900 900])
plot(Anchor_Microphone_1_Location(:,1),Anchor_Microphone_1_Location(:,2),'r*',Anchor_Microphone_2_Location(:,1),Anchor_Microphone_2_Location(:,2),'b*',Anchor_Location(:,1),Anchor_Location(:,2),'k*');
hold on;
plot(Microphone_1_Location(:,1),Microphone_1_Location(:,2),'r.',Microphone_2_Location(:,1),Microphone_2_Location(:,2),'b.',Microphone_Center_Location(:,1),Microphone_Center_Location(:,2),'k.');
hold on;
for i = 1:Anchor_Number
text(Anchor_Location(i,1)+0.3,Anchor_Location(i,2)+0.3,cellstr(num2str(i)));
end
for i = 1:Node_Number
text(Microphone_Center_Location(i,1)+0.3,Microphone_Center_Location(i,2)+0.3,cellstr(num2str(i+Anchor_Number)));
end
axis([-1 Size_Grid+1 -1 Size_Grid+1]) ;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
node_normal=Microphone_Center_Location; % 普通节点中心坐标
node_anchor = Anchor_Location; % 锚节点坐标
node_all = [node_anchor;node_normal];
dual_microphone_normal =[Microphone_1_Location Microphone_2_Location]; %% Node_Number*4
dual_microphone_anchor =[Anchor_Microphone_1_Location Anchor_Microphone_2_Location];
dual_node_all = [dual_microphone_anchor;dual_microphone_normal];
X_rank = calcul_rank(node_anchor,node_normal); % 生成序列号
table_binary = creat_table(dual_node_all,X_rank); % 生成对应对的0/1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%依次发声
Scale=4;%网格点放大尺度
L_Grid = Scale*Size_Grid; %%离散化点的个数  
W_Grid = Scale*Size_Grid; %%离散化点的个数  
%生成离散点
AreaX = 0 : Length/L_Grid : Size_Grid;
AreaY = 0 : Width/W_Grid : Size_Grid;
for i=0:L_Grid
    for j=0:W_Grid
        Grid_all(i*(L_Grid+1)+j+1,1) = AreaX(i+1);
        Grid_all(i*(W_Grid+1)+j+1,2) = AreaY(j+1);
    end
end
%%说明：初始化box为区域内所有的点%%
for normal_counter = 1:Node_Number
   box(normal_counter).count=(L_Grid+1)*(W_Grid+1);
   box(normal_counter).x=Grid_all(:,1);
   box(normal_counter).y=Grid_all(:,2);
   box(normal_counter).flag=ones(size(Grid_all(:,1)));
   box(normal_counter).count_angle = 360+zeros(size(Grid_all(:,1)));
%    box(normal_counter).ax = onescell(360);
   
    for ii= 1:360
       box(normal_counter).a_x(:,ii)= box(normal_counter).x+r*sin(ii/360*2*pi);
       box(normal_counter).a_y(:,ii)= box(normal_counter).y+r*cos(ii/360*2*pi);
       box(normal_counter).angle_flag(:,ii) = box(normal_counter).flag;
   end
end

for i = 1: Node_Number
    Xi = node_normal(i,:); %第 i 个节点发声
    Xi_1 = Microphone_1_Location(i,:); %第 i 个节点的麦克风1
    Xi_2 = Microphone_2_Location(i,:); %第 i 个节点的麦克风2   
    for j = 1 : Anchor_Number       
          %%% 根据锚节点 0/1信息 缩小 i节点范围
        Xj_1 = Anchor_Microphone_1_Location(j,:); %% 第j个锚节点 micphone 1 的位置
        Xj_2 = Anchor_Microphone_2_Location(j,:); %% 第j个锚节点 micphone 2 的位置
        temp_ang_flag = calcul_flag(Xi ,Xj_1,Xj_2);
       %%% 根据锚节点之间关系
        for k = j+1 : Anchor_Number
             anchor_flag = calcul_flag(Xi,node_anchor(j,:),node_anchor(k,:)); 
             for temp = 1 : 360
                 X_temp = [box(i).x(temp)  box(i).y(temp)];
                 temp_flag(temp) = calcul_flag( X_temp ,node_anchor(j,:),node_anchor(k,:));       
                 if (temp_flag(temp) == anchor_flag )
                    box(i).flag(temp) = 1; %% 满足条件赋值为1
                 else
                    box(i).flag(temp) = 0; %% 不满足条件赋值为0
                 end              
             end  
             box = update(box,Node_Number); %%% update box
        end       
        %%% 角度切割
        for temp = 1 : box(i).count
                 X_temp = [box(i).x(temp)  box(i).y(temp)];
                 temp_flag_angle(temp) = calcul_flag(X_temp,Xj_1,Xj_2);
                 if (temp_flag_angle(temp) == temp_ang_flag)
                    box(i).flag(temp) = 1; %% 满足条件赋值为1
                 else
                    box(i).flag(temp) = 0; %% 不满足条件赋值为0
                 end              
        end         
        box = update(box,Node_Number); %%% update box      
        
        %%%  角度范围 
         flag_angle = calcul_flag(node_anchor(j,:),Xi_1,Xi_2);
         for temp = 1 : box(i).count
              X_temp = [box(i).x(temp)  box(i).y(temp)];
%                 plot(box(i).x(temp),box(i).y(temp),'go');
               for t = 1:box(i).count_angle(temp) %% box(i).count_angle(temp) =360
                   X_ang = [box(i).a_x(temp,t) box(i).a_y(temp,t)]; %% 麦克风 1 所在的位置  
%                    plot(box(i).a_x(temp,t),box(i).a_y(temp,t),'g.');
                   flag_temp_angle = calcul_flag(node_anchor(j,:), X_ang,X_temp);    
                  if (flag_temp_angle ==  flag_angle )
                    box(i).angle_flag(temp,t) = 1;%% 满足条件赋值为1
                  else
                    box(i).angle_flag(temp,t) = 0;%% 不满足条件赋值为0  
                  end  
               end
          
         end  
      box = update_angle(box, Node_Number); %%% update box
    end
%%%% 普通节点修正
      for l = 1 :Node_Number
          if l ~= i
            Xl1 =Microphone_1_Location(l,:);
            Xl2 =Microphone_2_Location(l,:);
            flag_il = calcul_flag( Xi,Xl1,Xl2 );%%%  
            for temp_i = 1 : box(i).count %% 发声的区域
                     X_temp = [box(i).x(temp)  box(i).y(temp)];
                     temp_flag(temp) = calcul_flag(X_temp, Xl1, Xl2); %%% 真实 0 、 1 信息
                     for temp_l = 1 : box(l).count %%利用普通节点修正
                         XL_temp = [box(l).x(temp)  box(l).y(temp)];%% L节点区域里的离散点
                         for t = 1:box(l).count_angle(temp) %% box(l).count_angle(temp) <= 360
                             XL_ang = [box(l).a_x(temp,t) box(l).a_y(temp,t)]; %% 麦克风 1 所在的位置  
                             flag_temp_angle = calcul_flag(X_temp, XL_ang,XL_temp );    
                             if (temp_flag(temp) == flag_il)
                                box(i).flag(temp) = 1; %% 满足条件赋值为1
                             else
                                box(i).flag(temp) = 0; %%  不满足条件赋值为0
                             end   
                         end
                     end
                     box = update(box,Node_Number); %%% update box      
            end
          end
      end
 %%% 更新 i节点角度朝向
    for l = 1 :Node_Number
          if l ~= i
             Xl1 =Microphone_1_Location(l,:);
             Xl2 =Microphone_2_Location(l,:);
             flag_il = calcul_flag( Xi,Xl1,Xl2 );%%%  
             for temp_i = 1 : box(i).count %% 发声的区域    
                 for t = 1:box(l).count_angle(temp) %% box(l).count_angle(temp) <= 360
                     XL_ang = [box(l).a_x(temp,t) box(l).a_y(temp,t)]; %% 麦克风 1 所在的位置  
                     flag_temp_angle = calcul_flag(X_temp, XL_ang,XL_temp );    
                      for temp_l = 1 : box(l).count  
                          
                      end
                     
                             
                 end
             end
          end
    end
    
    
    
    
    
    
    
    
    
    
    
end
 
%%% 画出节点修正区域
for count = 1:Node_Number
    if count == 1
        for temp = 1 : box(count).count
            if  box(count).flag(temp) == 1
                plot(box(count).x(temp),box(count).y(temp),'ko');
                hold on;
                axis([-1 Size_Grid+1 -1 Size_Grid+1]) ;
            end 
        end
    end

    if count == 2
        for temp = 1 : box(count).count
            if  box(count).flag(temp) == 1
                plot(box(count).x(temp),box(count).y(temp),'bo');
                hold on;
                axis([-1 Size_Grid+1 -1 Size_Grid+1]) ;
            end
        end
    end
    
    
    if count == 3
        for temp = 1 : box(count).count
            if  box(count).flag(temp) == 1
                plot(box(count).x(temp),box(count).y(temp),'go');
                hold on;
                axis([-1 Size_Grid+1 -1 Size_Grid+1]) ;
            end
        end
    end
    if count == 4
        for temp = 1 : box(count).count
            if  box(count).flag(temp) == 1
                plot(box(count).x(temp),box(count).y(temp),'ro');
                hold on;
                axis([-1 Size_Grid+1 -1 Size_Grid+1]) ;
            end
        end
    end
    
    
    
end
% 
% tan(deg2rad(45));

debug = 0;
        
%         for l = 1 :Node_Number
%             Xl1 =Microphone_1_Location(l,:);
%             Xl2 =Microphone_2_Location(l,:);
%             flag_il = calcul_flag( Xi,Xl1,Xl2 );
%             for temp = 1 : box(i).count
%                      X_temp = [box(i).x(temp)  box(i).y(temp)];
%                      temp_flag(temp) = calcul_flag(X_temp, Xl1, Xl2);
%                      if (temp_flag(temp) == flag_il)
%                         box(i).flag(temp) = 1; %% 满足条件赋值为1
%                      else
%                         box(i).flag(temp) = 0; %%  不满足条件赋值为0
%                      end          
%             end
%         end
