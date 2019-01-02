clear;close all;
clc;clear;
addpath(genpath(cd));
%% settings
folder = 'Train\BSDS500';

DST_scale = 1;  %shearlet�ֽ��scale
Num_shrlt = 9;  %������scale�µõ���shearlet����

Savepath = cell(Num_shrlt,1);
for j = 1:Num_shrlt
    Savepath{j} = ['train_',num2str(j),'.h5'];
end

size_input = 96; %��������ͼ���Ĵ�С
size_label = size_input; %�������ͼ���Ĵ�С
stride = 48;
scale = 2;



%% initialization
data = zeros(size_input, size_input, 1, 1);     %data��labelһ��Ҫ��4ά�ģ���Ȼ���޷�ѵ��
label = cell(Num_shrlt,1);
for i = 1:Num_shrlt
    label{i} = zeros(size_label, size_label, 1, 1);
end
padding = abs(size_input - size_label)/2;

count = 0;

%% generate data
ext = {'*.jpg','*.png','*.bmp','*.tif'};
filepaths   =  [];
for i = 1 : length(ext)
    filepaths = cat(1,filepaths, dir(fullfile(folder,ext{i})));
end

for i = 1 : length(filepaths)
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
    
    [coeffs_DST_LR,~] = DSTImgDec(im_LR,DST_scale);     %��Сͼ����DST
    im_input = imresize(coeffs_DST_LR(:,:,9),scale,'bicubic');     %��DSTϵ����ֵ����Ϊ��������
    
    [coeffs_DST_gnd,~] = DSTImgDec(im_gnd,DST_scale);   %��gndͼ����DST����Ϊ����label
    
    
    for x = 1 : stride : hei-size_input+1
        for y = 1 :stride : wid-size_input+1
            count=count+1;
            data(:, :, 1, count) = im_input(x : x+size_input-1, y : y+size_input-1);
            subcoeffs_DST_gnd = coeffs_DST_gnd(x+padding : x+padding+size_label-1, y+padding : y+padding+size_label-1,:);
            
            for j = 1:Num_shrlt
                label{j}(:, :, 1, count) = subcoeffs_DST_gnd(:,:,j);
            end
        end
    end
end

%% shuffle the images
order = randperm(count);
data = data(:, :, 1, order);
for j = 1:Num_shrlt
    label{j}= label{j}(:,:,1, order);
end


%% writing to HDF5
chunksz = 32;
created_flag = false;
totalct = 0;

for batchno = 1:max(1,floor(count/chunksz))
    fprintf('Batch No.: %d \n', batchno);
    last_read=(batchno-1)*chunksz;
    batchdata = data(:,:,1, last_read+1:last_read+chunksz);
    
    for j = 1:Num_shrlt
        batchlabs{j} = label{j}(:,:,1, last_read+1:last_read+chunksz);
    end
    
    startloc = struct('dat',[1,1,1, totalct+1], 'lab', [1,1,1, totalct+1]);
    
    for j = 1:Num_shrlt
        curr_dat_sz{j} = store2hdf5(Savepath{j}, batchdata, batchlabs{j}, ~created_flag, startloc, chunksz);
    end
    
    created_flag = true;
    totalct = curr_dat_sz{1}(end);
end

for j = 1:Num_shrlt
    h5disp(Savepath{j})
end
