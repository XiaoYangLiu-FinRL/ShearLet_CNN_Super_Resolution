clear;close all;
clc;clear;
addpath(genpath(cd));
%% settings
folder = 'Train\BSDS500_train';
Savepath = 'train.h5';
chunksz = 64;

DST_scale = 1;  %shearlet�ֽ��scale
Num_shrlt = 9;  %������scale�µõ���shearlet����

size_input = 48; %��������ͼ���Ĵ�С
size_label = size_input; %�������ͼ���Ĵ�С
stride = 48;
scale = 2;

%% initialization
data = zeros(size_input, size_input, 1, 1);     %data��labelһ��Ҫ��4ά�ģ���Ȼ���޷�ѵ��
label = zeros(size_label, size_label, Num_shrlt, 1);
padding = abs(size_input - size_label)/2;

count = 0;

%% generate data
ext = {'*.jpg','*.png','*.bmp','*.tif'};
filepaths   =  [];
for i = 1 : length(ext)
    filepaths = cat(1,filepaths, dir(fullfile(folder,ext{i})));
end

%% part 1
for i = 1 : floor(length(filepaths)/5)      %����ÿ��Ҫ�����ͼƬ��������
    fprintf('Image No.: %d \n', i);
    image = imread(fullfile(folder,filepaths(i).name));
    
    if size(image,3)>1
        im_ycbcr = rgb2ycbcr(image);
        im_ycbcr = im_ycbcr(:, :, 1);
    end
    im_gnd = modcrop(im2double(im_ycbcr(:, :, 1)), scale);    %�������
    [hei,wid] = size(im_gnd);
    
    %     im_input = imresize(imresize(im_gnd, 1/scale, 'bicubic'),[hei,wid],'bicubic');    %��������
    
    im_LR = imresize(im_gnd, 1/scale, 'bicubic');       %ͼ���С
    
    im_bic = imresize(im_LR,scale,'bicubic');
        
    [coeffs_DST_gnd,~] = DSTImgDec(im_gnd,DST_scale);   %��gndͼ����DST����Ϊ����label
    
    
    for x = 1 : stride : hei-size_input+1
        for y = 1 :stride : wid-size_input+1
            count=count+1;            
            data(:, :, :, count) = im_bic(x : x+size_input-1, y : y+size_input-1,:);
            label(:, :, :, count) = coeffs_DST_gnd(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1,:);
        end
    end
end

% shuffle the images
order = randperm(count);
data = data(:, :, :, order);
label = label(:,:,:, order);

% writing to HDF5
created_flag = false;
totalct = 0;

for batchno = 1:max(1,floor(count/chunksz))
    fprintf('Batch No.: %d \n', batchno);
    last_read=(batchno-1)*chunksz;
    startloc = struct('dat',[1,1,1, totalct+1], 'lab', [1,1,1, totalct+1]);
    
    batchdata = data(:,:,:, last_read+1:last_read+chunksz);
    batchlabs = label(:,:,:, last_read+1:last_read+chunksz);
    
    curr_dat_sz = store2hdf5(Savepath, batchdata, batchlabs, ~created_flag, startloc, chunksz);
      
    created_flag = true;
    totalct = curr_dat_sz(end);
end

h5disp(Savepath)







%% part 2
count = 0;
data = zeros(size_input, size_input, 1, 1);     %data��labelһ��Ҫ��4ά�ģ���Ȼ���޷�ѵ��
label = zeros(size_label, size_label, Num_shrlt, 1);
for i = floor(length(filepaths)/5)+1 : 2*floor(length(filepaths)/5)
    fprintf('Image No.: %d \n', i);
    image = imread(fullfile(folder,filepaths(i).name));
    
    if size(image,3)>1
        im_ycbcr = rgb2ycbcr(image);
        im_ycbcr = im_ycbcr(:, :, 1);
    end
    im_gnd = modcrop(im2double(im_ycbcr(:, :, 1)), scale);    %�������
    [hei,wid] = size(im_gnd);
    
    %     im_input = imresize(imresize(im_gnd, 1/scale, 'bicubic'),[hei,wid],'bicubic');    %��������
    
    im_LR = imresize(im_gnd, 1/scale, 'bicubic');       %ͼ���С
    
    im_bic = imresize(im_LR,scale,'bicubic');
        
    [coeffs_DST_gnd,~] = DSTImgDec(im_gnd,DST_scale);   %��gndͼ����DST����Ϊ����label
    
    
    for x = 1 : stride : hei-size_input+1
        for y = 1 :stride : wid-size_input+1
            count=count+1;            
            data(:, :, :, count) = im_bic(x : x+size_input-1, y : y+size_input-1,:);
            label(:, :, :, count) = coeffs_DST_gnd(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1,:);
        end
    end
end

% shuffle the images
order = randperm(count);
data = data(:, :, :, order);
label = label(:,:,:, order);

% writing to HDF5
for batchno = 1:max(1,floor(count/chunksz))
    fprintf('Batch No.: %d \n', batchno);
    last_read=(batchno-1)*chunksz;
    startloc = struct('dat',[1,1,1, totalct+1], 'lab', [1,1,1, totalct+1]);
    
    batchdata = data(:,:,:, last_read+1:last_read+chunksz);
    batchlabs = label(:,:,:, last_read+1:last_read+chunksz);
    
    curr_dat_sz = store2hdf5(Savepath, batchdata, batchlabs, ~created_flag, startloc, chunksz);
      
    created_flag = true;
    totalct = curr_dat_sz(end);
end

h5disp(Savepath)



%% part 3
count = 0;
data = zeros(size_input, size_input, 1, 1);     %data��labelһ��Ҫ��4ά�ģ���Ȼ���޷�ѵ��
label = zeros(size_label, size_label, Num_shrlt, 1);
for i = 2*floor(length(filepaths)/5)+1 : 3*floor(length(filepaths)/5)
    fprintf('Image No.: %d \n', i);
    image = imread(fullfile(folder,filepaths(i).name));
    
    if size(image,3)>1
        im_ycbcr = rgb2ycbcr(image);
        im_ycbcr = im_ycbcr(:, :, 1);
    end
    im_gnd = modcrop(im2double(im_ycbcr(:, :, 1)), scale);    %�������
    [hei,wid] = size(im_gnd);
    
    %     im_input = imresize(imresize(im_gnd, 1/scale, 'bicubic'),[hei,wid],'bicubic');    %��������
    
    im_LR = imresize(im_gnd, 1/scale, 'bicubic');       %ͼ���С
    
    im_bic = imresize(im_LR,scale,'bicubic');
        
    [coeffs_DST_gnd,~] = DSTImgDec(im_gnd,DST_scale);   %��gndͼ����DST����Ϊ����label
    
    
    for x = 1 : stride : hei-size_input+1
        for y = 1 :stride : wid-size_input+1
            count=count+1;            
            data(:, :, :, count) = im_bic(x : x+size_input-1, y : y+size_input-1,:);
            label(:, :, :, count) = coeffs_DST_gnd(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1,:);
        end
    end
end

% shuffle the images
order = randperm(count);
data = data(:, :, :, order);
label = label(:,:,:, order);

% writing to HDF5
for batchno = 1:max(1,floor(count/chunksz))
    fprintf('Batch No.: %d \n', batchno);
    last_read=(batchno-1)*chunksz;
    startloc = struct('dat',[1,1,1, totalct+1], 'lab', [1,1,1, totalct+1]);
    
    batchdata = data(:,:,:, last_read+1:last_read+chunksz);
    batchlabs = label(:,:,:, last_read+1:last_read+chunksz);
    
    curr_dat_sz = store2hdf5(Savepath, batchdata, batchlabs, ~created_flag, startloc, chunksz);
      
    created_flag = true;
    totalct = curr_dat_sz(end);
end

h5disp(Savepath)



%% part 4
count = 0;
data = zeros(size_input, size_input, 1, 1);     %data��labelһ��Ҫ��4ά�ģ���Ȼ���޷�ѵ��
label = zeros(size_label, size_label, Num_shrlt, 1);
for i = 3*floor(length(filepaths)/5)+1 : 4*floor(length(filepaths)/5)
    fprintf('Image No.: %d \n', i);
    image = imread(fullfile(folder,filepaths(i).name));
    
    if size(image,3)>1
        im_ycbcr = rgb2ycbcr(image);
        im_ycbcr = im_ycbcr(:, :, 1);
    end
    im_gnd = modcrop(im2double(im_ycbcr(:, :, 1)), scale);    %�������
    [hei,wid] = size(im_gnd);
    
    %     im_input = imresize(imresize(im_gnd, 1/scale, 'bicubic'),[hei,wid],'bicubic');    %��������
    
    im_LR = imresize(im_gnd, 1/scale, 'bicubic');       %ͼ���С
    
    im_bic = imresize(im_LR,scale,'bicubic');
        
    [coeffs_DST_gnd,~] = DSTImgDec(im_gnd,DST_scale);   %��gndͼ����DST����Ϊ����label
    
    
    for x = 1 : stride : hei-size_input+1
        for y = 1 :stride : wid-size_input+1
            count=count+1;            
            data(:, :, :, count) = im_bic(x : x+size_input-1, y : y+size_input-1,:);
            label(:, :, :, count) = coeffs_DST_gnd(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1,:);
        end
    end
end

% shuffle the images
order = randperm(count);
data = data(:, :, :, order);
label = label(:,:,:, order);

% writing to HDF5
for batchno = 1:max(1,floor(count/chunksz))
    fprintf('Batch No.: %d \n', batchno);
    last_read=(batchno-1)*chunksz;
    startloc = struct('dat',[1,1,1, totalct+1], 'lab', [1,1,1, totalct+1]);
    
    batchdata = data(:,:,:, last_read+1:last_read+chunksz);
    batchlabs = label(:,:,:, last_read+1:last_read+chunksz);
    
    curr_dat_sz = store2hdf5(Savepath, batchdata, batchlabs, ~created_flag, startloc, chunksz);
      
    created_flag = true;
    totalct = curr_dat_sz(end);
end

h5disp(Savepath)



%% part 5
count = 0;
data = zeros(size_input, size_input, 1, 1);     %data��labelһ��Ҫ��4ά�ģ���Ȼ���޷�ѵ��
label = zeros(size_label, size_label, Num_shrlt, 1);
for i = 4*floor(length(filepaths)/5)+1 : length(filepaths)
    fprintf('Image No.: %d \n', i);
    image = imread(fullfile(folder,filepaths(i).name));
    
    if size(image,3)>1
        im_ycbcr = rgb2ycbcr(image);
        im_ycbcr = im_ycbcr(:, :, 1);
    end
    im_gnd = modcrop(im2double(im_ycbcr(:, :, 1)), scale);    %�������
    [hei,wid] = size(im_gnd);
    
    %     im_input = imresize(imresize(im_gnd, 1/scale, 'bicubic'),[hei,wid],'bicubic');    %��������
    
    im_LR = imresize(im_gnd, 1/scale, 'bicubic');       %ͼ���С
    
    im_bic = imresize(im_LR,scale,'bicubic');
        
    [coeffs_DST_gnd,~] = DSTImgDec(im_gnd,DST_scale);   %��gndͼ����DST����Ϊ����label
    
    
    for x = 1 : stride : hei-size_input+1
        for y = 1 :stride : wid-size_input+1
            count=count+1;            
            data(:, :, :, count) = im_bic(x : x+size_input-1, y : y+size_input-1,:);
            label(:, :, :, count) = coeffs_DST_gnd(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1,:);
        end
    end
end

% shuffle the images
order = randperm(count);
data = data(:, :, :, order);
label = label(:,:,:, order);

% writing to HDF5
for batchno = 1:max(1,floor(count/chunksz))
    fprintf('Batch No.: %d \n', batchno);
    last_read=(batchno-1)*chunksz;
    startloc = struct('dat',[1,1,1, totalct+1], 'lab', [1,1,1, totalct+1]);
    
    batchdata = data(:,:,:, last_read+1:last_read+chunksz);
    batchlabs = label(:,:,:, last_read+1:last_read+chunksz);
    
    curr_dat_sz = store2hdf5(Savepath, batchdata, batchlabs, ~created_flag, startloc, chunksz);
      
    created_flag = true;
    totalct = curr_dat_sz(end);
end

h5disp(Savepath)

