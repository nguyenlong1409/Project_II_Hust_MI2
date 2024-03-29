% 2d phương trình dao động màng theo phương pháp phần tử hữu hạn
clear all;clc;

% Các giá trị của phương trình: 
tmax=5;%thời gian dao động
m=400;%số lượng bước thời gian
tt=tmax/m;% bước thời gian (delta t)
c=1;%dữ liệu ban đầu
%Thực hiện chia miền ban đầu thành các miền con
n=20;%số điểm chia không gian => trên mỗi cạnh biên có 6 nút

% số tam giác là 4*n^2, số nút là n^2 + (n+1)^2
h=1/n;ef=4*n^2;pu=(n+1)^2+n^2;%ef điểm %pu=nút lưới
%Tạo ma trận t lưu các tam giác, mỗi tam giác được tạo thành từ ba nút
% Ma trận có kịch thước là (n^2*4) x 3
for j=1:n
    for i=(j-1)*n+1:j*n
        t(4*i-3,1)=i+j-1;t(4*i-2,1)=i+j-1;t(4*i-1,1)=i+j;t(4*i,1)=(n+1)^2+i;
        t(4*i-3,2)=(n+1)^2+i;t(4*i-2,2)=i+j;t(4*i-1,2)=n+1+i+j;t(4*i,2)=n+1+i+j;
        t(4*i-3,3)=n+i+j;t(4*i-2,3)=(n+1)^2+i;t(4*i-1,3)=(n+1)^2+i;t(4*i,3)=n+i+j;
    end
end
% Tạo ma trận p lưu tọa độ của các điểm nút (x,y)
% Ma trận có kích thước là (n^2+(n+1)^2) x 2
for j=1:n+1
    for i=(j-1)*(n+1)+1:j*(n+1)
        p(i,1)=(i-1-(j-1)*(n+1))*h;p(i,2)=(j-1)*h;
    end
end
for j=1:n
    for i=(j-1)*n+1:j*n
        pp(i,1)=(i-1-(j-1)*n)*h+(h/2);pp(i,2)=(j-1)*h+(h/2);
    end
end
p((n+1)^2+1:(n+1)^2+n^2,:)=pp;


% Phần tử hữu hạn 2D
% Xác định các điểm không thuộc biên và gán chỉ số
% Tính các ma trận S và M
ind=((p(:,1)>0 & p(:,1)<1)&(p(:,2)>0 & p(:,2)<1));%lấy ra chỉ số của các điểm nằm bên trong miền [0,1]x[0,1]
Np=size(p,1);N=sum(ind);% Np=# các nút; N=# các nút nội tiếp
in=zeros(Np,1);in(ind)=(1:N)';
S=zeros(N,N);%ma trận độ cứng
M=zeros(N,N);%ma trận khối lượng
for i=1:size(t,1)
j=t(i,1);k=t(i,2);l=t(i,3);
vj=in(j);vk=in(k);vl=in(l);
J=[p(k,1)-p(j,1), p(l,1)-p(j,1); p(k,2)-p(j,2), p(l,2)-p(j,2)];
ar=abs(det(J))/2; ar1=abs(det(J))/24;CC=ar/12; Q=inv(J'*J);
if vj>0 
    S(vj,vj)=S(vj,vj)+ar*sum(sum(Q));
    M(vj,vj)=M(vj,vj)+ar1*2;
end
if vk>0
    S(vk,vk)=S(vk,vk)+ar*Q(1,1);
    M(vk,vk)=M(vk,vk)+ar1*2;
end
if vl>0
    S(vl,vl)=S(vl,vl)+ar*Q(2,2);
    M(vl,vl)=M(vl,vl)+ar1*2;
end
if vj*vk>0
    S(vj,vk)=S(vj,vk)-ar*sum(Q(:,1)); S(vk,vj)=S(vj,vk);
    M(vj,vk)=M(vj,vk)+ar1; M(vk,vj)=M(vj,vk);
end
if vj*vl>0
    S(vj,vl)=S(vj,vl)-ar*sum(Q(:,2)); S(vl,vj)=S(vj,vl);
    M(vj,vl)=M(vj,vl)+ar1; M(vl,vj)=M(vj,vl);
end
if vk*vl>0
    S(vk,vl)=S(vk,vl)+ar*Q(1,2); S(vl,vk)=S(vk,vl);
    M(vk,vl)=M(vk,vl)+ar1; M(vl,vk)=M(vk,vl);
end
end

% Điều kiện ban đầu thực nghiệm
% ff là hàm mô tả điều kiện tại u(x,y,0)
U=zeros(pu,m+1);
V=zeros(pu,m+1);
ff = inline('sin(x.^2 + y.^2) ', 'x', 'y');% điều kiện ban đầu của màng
%ff=inline('exp(-(25*(x-0.5).^2+25*(y-0.5).^2))');
% Giá trị ban đầu của các phần tử trên màng
U(:,1)=ff(p(:,1),p(:,2));


UU=U;VV=V;Ne=Np-N;
indx=~((p(:,1)>0 & p(:,1)<1)&(p(:,2)>0 & p(:,2)<1));%được điểm viền trường hợp chung dom vuông
ix=(1:Np)';ii=ix(indx);
for i=1:Ne
    iix(i)=ii(Ne-i+1);
end
for i=iix
    UU(i,:)=[];%xóa các hàng và cột khỏi các chỉ số điểm biên 
    VV(i,:)=[];
end

% phương pháp CRANK NICHOLSON
gamma=(-c/2)*tt;
theta=tt/2;
MK1=(eye(N)-gamma*theta*M^-1*S);
MK2=(eye(N)+gamma*theta*M^-1*S);
MK3=2*gamma*M^-1*S;
for i=2:m+1
    VV(:,i)=MK1^-1*(MK2*VV(:,i-1)+MK3*UU(:,i-1));
    UU(:,i)=theta*(VV(:,i)+VV(:,i-1))+UU(:,i-1);       
end

%phép cộng vào ma trận U điều kiện biên dirichlet
U(ind,:)=UU;
V(ind,:)=VV;

% Biểu diễn đồ thị 
ttt=0:tt:tmax; %thời gian
for j=1:length(ttt)
    h=sprintf('%5.2f',ttt(j));
    set(gcf,'renderer','zbuffer');
    set(gca,'nextplot','replacechildren');
    caxis manual;caxis([min(min(U)) max(max(U))]);
    trisurf(t,p(:,1),p(:,2),U(:,j));
    title({['Miền [0,1] x [0,1]']; ...
        [num2str(ef),' miền con, ',num2str(pu),' nút']; ...
        ['Thời gian t = ',num2str(h),' s']});
    xlabel('x');ylabel('y');zlabel('U(x,y;t)');
    axis([0 1 0 1 min(min(U)) max(max(U))]);
    %view(0,90);shading interp;    
    XYZ(j)=getframe;
end
