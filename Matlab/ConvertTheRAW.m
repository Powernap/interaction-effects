c = textread('D:\Seafile\IVBG_intern\SylviWork\Paul\matrix_144x144x5_float.raw','%f');

fid = fopen('test.raw','w');
fwrite(fid,c,'float');
fclose(fid);