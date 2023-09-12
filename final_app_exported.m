classdef final_app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        alwaysrunningButton        matlab.ui.control.Button
        serialportTextAreaLabel_2  matlab.ui.control.Label
        sampleP                    matlab.ui.control.NumericEditField
        EditFieldLabel             matlab.ui.control.Label
        SSVEPLabel                 matlab.ui.control.Label
        stopIndicator              matlab.ui.control.Image
        rightIndicator             matlab.ui.control.Image
        leftIndicator              matlab.ui.control.Image
        backIndicator              matlab.ui.control.Image
        headIndicator              matlab.ui.control.Image
        runningtimeKnob            matlab.ui.control.Knob
        runningtimeKnobLabel       matlab.ui.control.Label
        serialportTextArea         matlab.ui.control.TextArea
        serialportTextAreaLabel    matlab.ui.control.Label
        ch8CheckBox                matlab.ui.control.CheckBox
        ch7CheckBox                matlab.ui.control.CheckBox
        Switch_2                   matlab.ui.control.ToggleSwitch
        ch6CheckBox                matlab.ui.control.CheckBox
        ch5CheckBox                matlab.ui.control.CheckBox
        ch4CheckBox                matlab.ui.control.CheckBox
        ch3CheckBox                matlab.ui.control.CheckBox
        ch2CheckBox                matlab.ui.control.CheckBox
        ch1CheckBox                matlab.ui.control.CheckBox
        Switch_2Label              matlab.ui.control.Label
        bluetoothButton            matlab.ui.control.Button
        Lamp                       matlab.ui.control.Lamp
        Switch                     matlab.ui.control.Switch
        Image                      matlab.ui.control.Image
        UIAxes                     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        mydevice % 暂存的device
        reference_label = [8.22 10.08 12.08 11.12] % 频率先验信息，下周记得改cca测试用频率
        channels_allow = [0,0,0,0,0,0,0,0]; % 一个数字编码一个通道的开关
        running_time = 1; % 保存单次运行时间
        is_running = 0; % 运行状态
        always_running = 0;
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: Switch
        function SwitchValueChanged(app, event)
% delete(gcp('nocreate'));            
% parpool(4);
% f1 = parfeval(@get_data, 1, "COM8", 256, 200);

fs = 250;

% [eegdata] = fetchOutputs(f1);
% delete(gcp('nocreate'));
%app.data = out1(2:9,:);
           
value = app.Switch.Value; % 获取开关的值
app.is_running = value;

if value == 1 % 如果开关打开
    set(app.Lamp,'color',[0,1,0]); % 将灯的颜色设置为绿色
    
while true
if app.is_running == 0
    break;
end

eegdata = get_data(app.serialportTextArea.Value{1}, fs, app.sampleP.Value);
%app.serialportTextArea.Value = num2str(isempty(eegdata));

  %对数据进行处理  分析并进行SSVEP分类  
  %找到SSVEP的分类标准  如何将结果可视化
  %用数据操纵小车
  
temp = app.channels_allow; % 拿到需要显示的通道掩码mask
channel_arr = temp;

% 设置保存文件的路径
desktopPath = fullfile(pwd,"data");
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = ['EEG_' timestamp '.mat'];
filePath = fullfile(desktopPath, filename);

% mask = repmat(temp',1,size(eegdata,2));
% %eegdata(1:2,:)
% temp = eegdata.* mask;
%eegdata = eegdata-mean(eegdata,2); % 去除直流分量
%eegdata = filtfilt(b,a,eegdata')'; % 对数据进行滤波
% eegdata = eegdata(:,79:end); % 去除滤波器的初始响应


new_eeg = [];
for index_ch = 1:8
    if channel_arr(index_ch) == 1
        new_eeg = [new_eeg; eegdata(index_ch,:)];
    end
end

temp = new_eeg(:,79:end);

% for time_id = 1:size(temp,3)
for index_i = 1:size(temp,1)
    temp(index_i,:) = my_filter(squeeze(new_eeg(index_i,:)), fs, 4, 40, 50, 50);
end
%end

eeg_procss = temp;


save(filePath, 'eegdata', 'channel_arr', 'eeg_procss');
% 显示保存成功消息
disp(['数据已保存到文件：' filePath]);

% eeg_show = [];
% for time_id = 1:size(eeg_procss,3)
%     eeg_show = cat(2,eeg_show,eeg_procss(:,:,time_id));
% end

eegdata_show = fft(eeg_procss')';
xcorr = -fs/2:fs/size(eegdata_show,2):fs/2-fs/size(eegdata_show,2);
eegdata_show = eegdata_show(:,1:round(end/2)+1);
xcorr = xcorr(end - size(eegdata_show,2)+1:end);
eegdata_show = abs(eegdata_show);
%eegdata_show = eegdata .* mask;

%eegdata_show
%eegdata(1:2,:)



cla(app.UIAxes);
%xlim(app.UIAxes,[0,50])
%ylim(app.UIAxes,[-500,500])
plot(app.UIAxes,xcorr,eegdata_show); 
hold(app.UIAxes,"on");
title(app.UIAxes,string(datetime)); 

eeg_cca = eeg_procss;
%for time_id = 1:size(eeg_procss,3)
%    eeg_cca = cat(1,eeg_cca,eeg_procss(:,:,time_id));
%end

predict = cca(eeg_cca, app.reference_label, fs);


%% car

%%
% num = ['5A';'A5';'04';'01';'00';'05';'AA'];
front =       hex2dec(['5A';'A5';'04';'01';'00';'05';'AA']);
left_front =  hex2dec(['5A';'A5';'04';'01';'01';'06';'AA']);
left =        hex2dec(['5A';'A5';'04';'00';'01';'05';'AA']);
left_rear =   hex2dec(['5A';'A5';'04';'02';'01';'07';'AA']);
rear =        hex2dec(['5A';'A5';'04';'02';'00';'06';'AA']);
right_rear =  hex2dec(['5A';'A5';'04';'02';'02';'08';'AA']);
right =       hex2dec(['5A';'A5';'04';'00';'02';'06';'AA']);
right_front = hex2dec(['5A';'A5';'04';'01';'02';'07';'AA']);
stop = hex2dec(['5A';'A5';'04';'00';'00';'04';'AA']);

switch predict
    case app.reference_label(1) % 前进
        app.stopIndicator.Visible = "Off";
        app.headIndicator.Visible = "On";
        write(app.mydevice,front,'string');
        
        if app.always_running == 0
            pause(app.running_time);
            write(app.mydevice,stop,'string');
        end
        %write(app.mydevice,stop,'string')
        app.headIndicator.Visible = "Off";
        app.stopIndicator.Visible = "On";
        
    
    case app.reference_label(2) % 后退
        app.stopIndicator.Visible = "Off";
       app.backIndicator.Visible = "On";
        write(app.mydevice,rear,'string')
        %pause(app.running_time)
        
        if app.always_running == 0
            pause(app.running_time);
            write(app.mydevice,stop,'string')
        end
        %write(app.mydevice,stop,'string')
        app.backIndicator.Visible = "Off";
        app.stopIndicator.Visible = "On";
    
    case app.reference_label(3) % 左转
        app.stopIndicator.Visible = "Off";
        app.leftIndicator.Visible = "On";
        write(app.mydevice,left,'string')
        %pause(app.running_time)
        
        if app.always_running == 0
            pause(app.running_time);
            write(app.mydevice,stop,'string')
        end
        %write(app.mydevice,stop,'string')
        app.leftIndicator.Visible = "Off";
        app.stopIndicator.Visible = "On";
    
    case app.reference_label(4) % 右转
        app.stopIndicator.Visible = "Off";
        app.rightIndicator.Visible = "On";
        write(app.mydevice,right,'string') 
        %pause(app.running_time)
        
        if app.always_running == 0
            pause(app.running_time);
            write(app.mydevice,stop,'string')
        end
        %write(app.mydevice,stop,'string')
        app.rightIndicator.Visible = "Off";
        app.stopIndicator.Visible = "On";
        
end


%%
% device = bluetooth('HC-06');
% configureTerminator(device,'CR/LF');
% num = ['5A';'A5';'04';'00';'00';'04';'AA'];




end


end

if app.Switch.Value == 0 % 如果开关关闭
    set(app.Lamp,'color',[0.65,0.65,0.65]) % 将灯的颜色设置为灰色
end

function eegdata = get_data(port,fs,num_data)
% port:串口名，例如“COM8”
% fs:采样率，例如：256
% num_data:采集的数据个数，不建议超过采样率的数值，例如：200
% pause(5);
addpath("./brainflowmatlab");
BoardShim.set_log_file('brainflow.log');
BoardShim.enable_dev_board_logger();

params = BrainFlowInputParams();
params.serial_port=port;
board_shim = BoardShim(int32(BoardIds.CYTON_BOARD), params);
preset = int32(BrainFlowPresets.DEFAULT_PRESET);
board_shim.prepare_session();
board_shim.add_streamer('file://data_default.csv:w', preset);
board_shim.start_stream(num_data, ''); % 开始程序，采样256HZ

%time_limit = ceil(num_data/fs);
%eegdata = zeros(8,fs);
%eegdata = [];
%for i=1:time_limit
    pause(ceil(num_data/fs)+1); % 采集一段时间，必须有，否则拿不到数据
    data_temp = board_shim.get_current_board_data(num_data, preset); % 只要前250个数据，拿到的数据是24*200；24通道中第2-9通道对应采集到的1-8通道原始数据
    %eegdata(:,(i-1)*fs+1:i*fs) = data_temp(2:9,:); % 获取 EEG 数据
    eegdata = data_temp(2:9,:);
    %eegdata = eegdata(2:9,:);
%end
board_shim.stop_stream(); % 停止程序

%    if size(eegdata,2) > num_data
%        eegdata = eegdata(:,1:num_data);
%        
%    end

  %board_shim.stop_stream();   % 停止流式传输数据
  board_shim.release_session();
end


function [predict] = cca(signal, ref_signals, fs)

% Filter the signal
% for i = 1:size(signal,1)
%     signal(i,:) = my_filter(signal(i,:), fs, 1, 100, 50, 50);
% end
% signal = signal(:,length(signal)-1024+1:length(signal));

% Find SSVEP frequency and maximum canonical correlation
[predict, ~] = find_ssvep_freq(signal, ref_signals, 4, fs);
end

function [signal_filt] = my_filter(signal, fs, fl, fh, f0, Q)
% Bandpass filter
n = 4;  % Filter order
[b_band, a_band] = butter(n, [fl, fh]/(fs/2));
signal_filt = filtfilt(b_band, a_band, signal);  % Double-direction filtering to reduce transient response influence

signal_filt = signal_filt - mean(signal_filt);  % Remove mean

signal_filt = signal_filt(:,79:end); % 去除滤波器的初始响应

% 50Hz Butterworth notch filter
W0 = f0 / (fs/2);
bw = 2*W0/Q;
[b_notch, a_notch] = butter(n, [W0-bw, W0+bw], 'stop');
signal_filt = filtfilt(b_notch, a_notch, signal_filt);
end

function [fs, rho_max] = find_ssvep_freq(eeg, ref_signals, N_harm, Fs)
% Input:
%   eeg: A preprocessed EEG signal column vector
%   ref_signals: Reference signal matrix, with each column representing a specific frequency reference signal
%   N_harm: Number of harmonic frequencies for each reference signal
%
% Output:
%   fs: Estimated SSVEP frequency (Hz)
%   rho_max: Maximum canonical correlation coefficient

% Build reference signals for each frequency
freqs = ref_signals;
N_ref = length(freqs);
N_samples = length(eeg);
ref_signals_all = zeros(N_samples, N_harm*N_ref*2);
for i = 1:N_ref
    freq = freqs(i);
    ref_signals_i = zeros(N_samples, N_harm*2);
    for j = 1:N_harm
        ref_signals_i(:,(j-1)*2+1) = sin(2*pi*j*freq*(0:N_samples-1)/Fs);
        ref_signals_i(:,j*2) = cos(2*pi*j*freq*(0:N_samples-1)/Fs);
    end
    ref_signals_all(:,(i-1)*N_harm*2+1:i*N_harm*2) = ref_signals_i;
end

% Apply CCA algorithm to compute the canonical correlation coefficients between EEG data and each reference signal
rho = zeros(N_ref, 1);
for i = 1:N_ref
    [~, ~, r] = canoncorr(eeg', ref_signals_all(:,(i-1)*N_harm*2+1:i*N_harm*2));
    rho(i) = max(r);
end

% Find the reference signal with the highest canonical correlation coefficient
[rho_max, ind] = max(rho);
fs = freqs(ind);
end

        end

        % Button down function: UIAxes
        function UIAxesButtonDown(app, event)
            
        end

        % Callback function
        function ButtonValueChanged(app, event)
            value = app.alwaysrunningButton.Value;
            %接受受试者的反馈- 重测

             cla(app.UIAxes); 
           

        end

        % Button pushed function: bluetoothButton
        function bluetoothButtonPushed(app, event)
            
            
            
            
            app.mydevice = bluetooth('HC-06');
            configureTerminator(app.mydevice,'CR/LF');
%             myGUI;

            app.Switch.Enable = true;
            
            
            
            
          
        end

        % Value changed function: Switch_2
        function Switch_2ValueChanged(app, event)
            value = app.Switch_2.Value;
            if value == "On"
                app.ch1CheckBox.Visible = 'On';
                app.ch2CheckBox.Visible = 'On';
                app.ch3CheckBox.Visible = 'On';
                app.ch4CheckBox.Visible = 'On';
                app.ch5CheckBox.Visible = 'On';
                app.ch6CheckBox.Visible = 'On';
                app.ch7CheckBox.Visible = 'On';
                app.ch8CheckBox.Visible = 'On';
            else
                app.ch1CheckBox.Visible = 'Off';
                app.ch2CheckBox.Visible = 'Off';
                app.ch3CheckBox.Visible = 'Off';
                app.ch4CheckBox.Visible = 'Off';
                app.ch5CheckBox.Visible = 'Off';
                app.ch6CheckBox.Visible = 'Off';
                app.ch7CheckBox.Visible = 'Off';
                app.ch8CheckBox.Visible = 'Off';
            end
        end

        % Value changed function: ch1CheckBox
        function ch1CheckBoxValueChanged(app, event)
            value = app.ch1CheckBox.Value;
            if value == 1
                app.channels_allow(1) = 1;
                
            else
                app.channels_allow(1) = 0;
                
            end
            
        end

        % Value changed function: ch2CheckBox
        function ch2CheckBoxValueChanged(app, event)
            value = app.ch2CheckBox.Value;
            if value == 1
                app.channels_allow(2) = 1;
                
            else
                app.channels_allow(2) = 0;
                
            end
        end

        % Value changed function: ch3CheckBox
        function ch3CheckBoxValueChanged(app, event)
            value = app.ch3CheckBox.Value;
            if value == 1
                app.channels_allow(3) = 1;
                
            else
                app.channels_allow(3) = 0;
                
            end
        end

        % Value changed function: ch4CheckBox
        function ch4CheckBoxValueChanged(app, event)
            value = app.ch4CheckBox.Value;
            if value == 1
                app.channels_allow(4) = 1;
                
            else
                app.channels_allow(4) = 0;
                
            end
        end

        % Value changed function: ch5CheckBox
        function ch5CheckBoxValueChanged(app, event)
            value = app.ch5CheckBox.Value;
            if value == 1
                app.channels_allow(5) = 1;
                
            else
                app.channels_allow(5) = 0;
                
            end
        end

        % Value changed function: ch6CheckBox
        function ch6CheckBoxValueChanged(app, event)
            value = app.ch6CheckBox.Value;
            if value == 1
                app.channels_allow(6) = 1;
                
            else
                app.channels_allow(6) = 0;
                
            end
        end

        % Value changed function: ch7CheckBox
        function ch7CheckBoxValueChanged(app, event)
            value = app.ch7CheckBox.Value;
            if value == 1
                app.channels_allow(7) = 1;
                
            else
                app.channels_allow(7) = 0;
                
            end
        end

        % Value changed function: ch8CheckBox
        function ch8CheckBoxValueChanged(app, event)
            value = app.ch8CheckBox.Value;
            if value == 1
                app.channels_allow(8) = 1;
                
            else
                app.channels_allow(8) = 0;
                
            end
        end

        % Value changed function: runningtimeKnob
        function runningtimeKnobValueChanged(app, event)
            value = app.runningtimeKnob.Value;
            app.running_time = value;
        end

        % Button pushed function: alwaysrunningButton
        function alwaysrunningButtonPushed(app, event)
            if app.always_running == 1
                app.always_running = 0;
                app.alwaysrunningButton.Text = 'always running';
                stop = hex2dec(['5A';'A5';'04';'00';'00';'04';'AA']);
                write(app.mydevice,stop,'string')
            else
                app.always_running = 1;
                app.alwaysrunningButton.Text = 'manual running';
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.302 0.7451 0.9333];
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            xlabel(app.UIAxes, 'frequency')
            ylabel(app.UIAxes, 'Signal')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontName = 'Times New Roman';
            app.UIAxes.XColor = [1 1 1];
            app.UIAxes.YColor = [1 1 1];
            app.UIAxes.ZColor = [1 1 1];
            app.UIAxes.Color = 'none';
            app.UIAxes.XGrid = 'on';
            app.UIAxes.FontSize = 12;
            app.UIAxes.GridColor = [1 1 1];
            app.UIAxes.MinorGridColor = [0.902 0.902 0.902];
            app.UIAxes.ButtonDownFcn = createCallbackFcn(app, @UIAxesButtonDown, true);
            app.UIAxes.Position = [19 286 604 185];

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.ScaleMethod = 'fill';
            app.Image.Position = [1 1 641 286];
            app.Image.ImageSource = 'background.jpeg';

            % Create Switch
            app.Switch = uiswitch(app.UIFigure, 'slider');
            app.Switch.ItemsData = [0 1];
            app.Switch.ValueChangedFcn = createCallbackFcn(app, @SwitchValueChanged, true);
            app.Switch.FontName = 'Times New Roman';
            app.Switch.FontSize = 14;
            app.Switch.FontColor = [1 1 1];
            app.Switch.Position = [76 219 45 20];
            app.Switch.Value = 0;

            % Create Lamp
            app.Lamp = uilamp(app.UIFigure);
            app.Lamp.Position = [160 219 20 20];
            app.Lamp.Color = [0.651 0.651 0.651];

            % Create bluetoothButton
            app.bluetoothButton = uibutton(app.UIFigure, 'push');
            app.bluetoothButton.ButtonPushedFcn = createCallbackFcn(app, @bluetoothButtonPushed, true);
            app.bluetoothButton.FontName = 'Times New Roman';
            app.bluetoothButton.Position = [301 238 61 23];
            app.bluetoothButton.Text = 'bluetooth';

            % Create Switch_2Label
            app.Switch_2Label = uilabel(app.UIFigure);
            app.Switch_2Label.HorizontalAlignment = 'center';
            app.Switch_2Label.FontName = 'Times New Roman';
            app.Switch_2Label.FontSize = 14;
            app.Switch_2Label.FontColor = [1 1 1];
            app.Switch_2Label.Position = [160 25 44 22];
            app.Switch_2Label.Text = 'Switch';

            % Create ch1CheckBox
            app.ch1CheckBox = uicheckbox(app.UIFigure);
            app.ch1CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch1CheckBoxValueChanged, true);
            app.ch1CheckBox.Visible = 'off';
            app.ch1CheckBox.Text = 'ch1';
            app.ch1CheckBox.FontName = 'Times New Roman';
            app.ch1CheckBox.FontSize = 14;
            app.ch1CheckBox.FontColor = [1 1 1];
            app.ch1CheckBox.Position = [30 114 81 22];

            % Create ch2CheckBox
            app.ch2CheckBox = uicheckbox(app.UIFigure);
            app.ch2CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch2CheckBoxValueChanged, true);
            app.ch2CheckBox.Visible = 'off';
            app.ch2CheckBox.Text = 'ch2';
            app.ch2CheckBox.FontName = 'Times New Roman';
            app.ch2CheckBox.FontSize = 14;
            app.ch2CheckBox.FontColor = [1 1 1];
            app.ch2CheckBox.Position = [30 93 81 22];

            % Create ch3CheckBox
            app.ch3CheckBox = uicheckbox(app.UIFigure);
            app.ch3CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch3CheckBoxValueChanged, true);
            app.ch3CheckBox.Visible = 'off';
            app.ch3CheckBox.Text = 'ch3';
            app.ch3CheckBox.FontName = 'Times New Roman';
            app.ch3CheckBox.FontSize = 14;
            app.ch3CheckBox.FontColor = [1 1 1];
            app.ch3CheckBox.Position = [30 72 81 22];

            % Create ch4CheckBox
            app.ch4CheckBox = uicheckbox(app.UIFigure);
            app.ch4CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch4CheckBoxValueChanged, true);
            app.ch4CheckBox.Visible = 'off';
            app.ch4CheckBox.Text = 'ch4';
            app.ch4CheckBox.FontName = 'Times New Roman';
            app.ch4CheckBox.FontSize = 14;
            app.ch4CheckBox.FontColor = [1 1 1];
            app.ch4CheckBox.Position = [30 51 81 22];

            % Create ch5CheckBox
            app.ch5CheckBox = uicheckbox(app.UIFigure);
            app.ch5CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch5CheckBoxValueChanged, true);
            app.ch5CheckBox.Visible = 'off';
            app.ch5CheckBox.Text = 'ch5';
            app.ch5CheckBox.FontName = 'Times New Roman';
            app.ch5CheckBox.FontSize = 14;
            app.ch5CheckBox.FontColor = [1 1 1];
            app.ch5CheckBox.Position = [95 114 81 22];

            % Create ch6CheckBox
            app.ch6CheckBox = uicheckbox(app.UIFigure);
            app.ch6CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch6CheckBoxValueChanged, true);
            app.ch6CheckBox.Visible = 'off';
            app.ch6CheckBox.Text = 'ch6';
            app.ch6CheckBox.FontName = 'Times New Roman';
            app.ch6CheckBox.FontSize = 14;
            app.ch6CheckBox.FontColor = [1 1 1];
            app.ch6CheckBox.Position = [95 93 81 22];

            % Create Switch_2
            app.Switch_2 = uiswitch(app.UIFigure, 'toggle');
            app.Switch_2.ValueChangedFcn = createCallbackFcn(app, @Switch_2ValueChanged, true);
            app.Switch_2.FontName = 'Times New Roman';
            app.Switch_2.FontSize = 14;
            app.Switch_2.FontColor = [1 1 1];
            app.Switch_2.Position = [171 83 20 45];

            % Create ch7CheckBox
            app.ch7CheckBox = uicheckbox(app.UIFigure);
            app.ch7CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch7CheckBoxValueChanged, true);
            app.ch7CheckBox.Visible = 'off';
            app.ch7CheckBox.Text = 'ch7';
            app.ch7CheckBox.FontName = 'Times New Roman';
            app.ch7CheckBox.FontSize = 14;
            app.ch7CheckBox.FontColor = [1 1 1];
            app.ch7CheckBox.Position = [95 72 81 22];

            % Create ch8CheckBox
            app.ch8CheckBox = uicheckbox(app.UIFigure);
            app.ch8CheckBox.ValueChangedFcn = createCallbackFcn(app, @ch8CheckBoxValueChanged, true);
            app.ch8CheckBox.Visible = 'off';
            app.ch8CheckBox.Text = 'ch8';
            app.ch8CheckBox.FontName = 'Times New Roman';
            app.ch8CheckBox.FontSize = 14;
            app.ch8CheckBox.FontColor = [1 1 1];
            app.ch8CheckBox.Position = [95 51 81 22];

            % Create serialportTextAreaLabel
            app.serialportTextAreaLabel = uilabel(app.UIFigure);
            app.serialportTextAreaLabel.HorizontalAlignment = 'right';
            app.serialportTextAreaLabel.FontName = 'Times New Roman';
            app.serialportTextAreaLabel.FontSize = 14;
            app.serialportTextAreaLabel.FontColor = [1 1 1];
            app.serialportTextAreaLabel.Position = [238 202 61 22];
            app.serialportTextAreaLabel.Text = 'serial port';

            % Create serialportTextArea
            app.serialportTextArea = uitextarea(app.UIFigure);
            app.serialportTextArea.FontName = 'Times New Roman';
            app.serialportTextArea.Position = [314 205 48 21];
            app.serialportTextArea.Value = {'COM8'};

            % Create runningtimeKnobLabel
            app.runningtimeKnobLabel = uilabel(app.UIFigure);
            app.runningtimeKnobLabel.HorizontalAlignment = 'center';
            app.runningtimeKnobLabel.FontName = 'Times New Roman';
            app.runningtimeKnobLabel.FontSize = 14;
            app.runningtimeKnobLabel.FontColor = [1 1 1];
            app.runningtimeKnobLabel.Position = [277 25 77 22];
            app.runningtimeKnobLabel.Text = 'running time';

            % Create runningtimeKnob
            app.runningtimeKnob = uiknob(app.UIFigure, 'continuous');
            app.runningtimeKnob.Limits = [1 11];
            app.runningtimeKnob.ValueChangedFcn = createCallbackFcn(app, @runningtimeKnobValueChanged, true);
            app.runningtimeKnob.FontName = 'Times New Roman';
            app.runningtimeKnob.FontSize = 14;
            app.runningtimeKnob.FontColor = [1 1 1];
            app.runningtimeKnob.Position = [285 85 60 60];
            app.runningtimeKnob.Value = 1;

            % Create headIndicator
            app.headIndicator = uiimage(app.UIFigure);
            app.headIndicator.Visible = 'off';
            app.headIndicator.Position = [473 75 100 100];
            app.headIndicator.ImageSource = 'arrow_w.png';

            % Create backIndicator
            app.backIndicator = uiimage(app.UIFigure);
            app.backIndicator.Visible = 'off';
            app.backIndicator.Position = [473 73 100 100];
            app.backIndicator.ImageSource = 'arrow_s.png';

            % Create leftIndicator
            app.leftIndicator = uiimage(app.UIFigure);
            app.leftIndicator.Visible = 'off';
            app.leftIndicator.Position = [473 75 100 100];
            app.leftIndicator.ImageSource = 'arrow_a.png';

            % Create rightIndicator
            app.rightIndicator = uiimage(app.UIFigure);
            app.rightIndicator.Visible = 'off';
            app.rightIndicator.Position = [473 73 100 100];
            app.rightIndicator.ImageSource = 'arrow_d.png';

            % Create stopIndicator
            app.stopIndicator = uiimage(app.UIFigure);
            app.stopIndicator.Position = [473 75 100 100];
            app.stopIndicator.ImageSource = 'stop.png';

            % Create SSVEPLabel
            app.SSVEPLabel = uilabel(app.UIFigure);
            app.SSVEPLabel.HorizontalAlignment = 'center';
            app.SSVEPLabel.FontName = 'Times New Roman';
            app.SSVEPLabel.FontSize = 16;
            app.SSVEPLabel.FontWeight = 'bold';
            app.SSVEPLabel.FontColor = [1 1 1];
            app.SSVEPLabel.Position = [294 459 55 22];
            app.SSVEPLabel.Text = 'SSVEP';

            % Create EditFieldLabel
            app.EditFieldLabel = uilabel(app.UIFigure);
            app.EditFieldLabel.HorizontalAlignment = 'right';
            app.EditFieldLabel.Position = [191 174 56 22];
            app.EditFieldLabel.Text = 'Edit Field';

            % Create sampleP
            app.sampleP = uieditfield(app.UIFigure, 'numeric');
            app.sampleP.Position = [314 174 48 22];
            app.sampleP.Value = 1000;

            % Create serialportTextAreaLabel_2
            app.serialportTextAreaLabel_2 = uilabel(app.UIFigure);
            app.serialportTextAreaLabel_2.HorizontalAlignment = 'right';
            app.serialportTextAreaLabel_2.FontName = 'Times New Roman';
            app.serialportTextAreaLabel_2.FontSize = 14;
            app.serialportTextAreaLabel_2.FontColor = [1 1 1];
            app.serialportTextAreaLabel_2.Position = [216 174 83 22];
            app.serialportTextAreaLabel_2.Text = 'sample points';

            % Create alwaysrunningButton
            app.alwaysrunningButton = uibutton(app.UIFigure, 'push');
            app.alwaysrunningButton.ButtonPushedFcn = createCallbackFcn(app, @alwaysrunningButtonPushed, true);
            app.alwaysrunningButton.Position = [473 236 100 22];
            app.alwaysrunningButton.Text = 'always running';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = final_app_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end