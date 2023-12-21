% function f = sh7(x)
% Shekel7 function
function f = sh7(x)
a = [4, 1, 8, 6, 3, 2, 5;
     4, 1, 8, 6, 7, 9, 5;
     4, 1, 8, 6, 3, 2, 3;
     4, 1, 8, 6, 7, 9, 3];
c = [0.1 0.2 0.2 0.4 0.4 0.6 0.3];
if size(x,1) == 1
 x = x';
end
for i=1:7
 b = (x - a(:,i)).^2;
 d(i) = sum(b);
end
f = -sum((c+d).^(-1));
