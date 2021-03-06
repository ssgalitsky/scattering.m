function [sounds, texts] = eca_synthesize(y, archs, opts)
%% Default options
opts.generate_text = default(opts, 'generate_text', false);
if opts.generate_text
    opts.nLines = default(opts, 'nLines', Inf);
end
opts.display_text = default(opts, 'display_text', false);
opts.adapt_learning_rate = default(opts, 'adapt_learning_rate', false);
opts = fill_reconstruction_opt(opts);

%% Split target into chunks
N = archs{1}.banks{1}.spec.size;
target_chunks = eca_split(y, N);
nChunks = size(target_chunks, 2);

%% Group target chunks into batches
nChunks_per_batch = min(nChunks, opts.nChunks_per_batch);
% We want to avoid having only one chunk in the last batch
if mod(nChunks, nChunks_per_batch) == 1
    nBatches = (nChunks - 1) / nChunks_per_batch;
else
    nBatches = ceil(nChunks / nChunks_per_batch);
end
target_batches = cell(1, nBatches);
batch_sizes = zeros(1, nBatches);
for batch_index = 0:(nBatches-1)
    batch_start = 1 + batch_index * nChunks_per_batch;
    batch_stop = min((batch_index+1) * nChunks_per_batch, nChunks);
    if batch_stop == (nChunks - 1)
        batch_stop = nChunks;
    end
    target_batches{1+batch_index} = target_chunks(:, batch_start:batch_stop);
    batch_sizes(1+batch_index) = batch_stop - batch_start + 1;
end

%% Forward propagation of target
target_S_batches = cell(1, nBatches);
parfor batch_index = 0:(nBatches-1)
    target_S_batches{1+batch_index} = ...
        eca_propagate(target_batches{1+batch_index}, archs);
end

%% Initialization
loss_batches = zeros(nBatches, opts.nIterations);
signal_update_batches = ...
    arrayfun(@(x) zeros(N, x), batch_sizes, 'UniformOutput', false);
learning_rate_batches = opts.initial_learning_rate * ones(1, nBatches);
max_nDigits = 1 + floor(log10(opts.nIterations));
sprintf_format = ['%0.', num2str(max_nDigits), 'd'];
texts = cell(1, 1 + opts.nIterations);
sounds = cell(1, 1 + opts.nIterations);
hann_window = hann(N);
chunks = zeros(N, nChunks);
if opts.is_initialization_localized
    for chunk_index = 0:(nChunks-1)
        chunk = generate_colored_noise(target_chunks(:, 1+chunk_index));
        chunk = chunk .* hann_window;
        chunks(:, 1+chunk_index) = chunk;
    end
    sounds{1+0} = eca_overlap_add(chunks);
else
    sounds{1+0} = generate_colored_noise(y);
end

%% Iterated reconstruction
generate_text = opts.generate_text;
iteration = 1;
U_batches = cell(1, nBatches);
figure_handle = gcf();
tic();
while (iteration <= opts.nIterations) && ishandle(figure_handle)
    %% Split into chunks
    chunks = eca_split(sounds{iteration}, N);
    
    %% Batch computation
    batches = cell(1, nBatches);
    for batch_index = 0:(nBatches-1)
        % Select chunks
        batch_start = 1 + batch_index * nChunks_per_batch;
        batch_stop = min((batch_index+1) * nChunks_per_batch, nChunks);
        if batch_stop == (nChunks - 1)
            batch_stop = nChunks;
        end
        batches{1+batch_index} = chunks(:, batch_start:batch_stop);
    end
    if opts.generate_text
        S_batches = cell(1, nBatches);
    end
    parfor batch_index = 0:(nBatches-1)
        % Load batch
        batch = batches{1+batch_index};
        % Forward propagation
        [S, U, Y] = eca_propagate(batch, archs);
        if generate_text
            S_batches{1+batch_index} = S;
        end
        U_batches{1+batch_index} = U(1:2);
        target_S = target_S_batches{1+batch_index};
        % Substraction
        delta_S = sc_substract(target_S, S);
        % Backpropagation
        delta_batch = sc_backpropagate(delta_S, U, Y, archs);
        % Get learning rate and momentum
        learning_rate = learning_rate_batches(1+batch_index);
        signal_update = signal_update_batches{1+batch_index};
        % Update signal
        [batch, signal_update] = update_reconstruction(batch, delta_batch, ...
            signal_update, learning_rate, opts);
        batches{1+batch_index} = batch;
        % Update learning rate and momentum
        learning_rate_batches(1+batch_index) = learning_rate;
        signal_update_batches{1+batch_index} = signal_update;
    end
    chunks = [batches{:}];
    sounds{1+iteration} = eca_overlap_add(chunks);
    
    %% Pretty-printing of scattering distances and loss function
     if opts.is_verbose
         if opts.adapt_learning_rate
            average_learning_rate = mean(learning_rate_batches);
            average_learning_rate_str = ...
                num2str(average_learning_rate, '%0.4f');
            disp(['Average learning rate = ', average_learning_rate_str]);
         end
         toc();
         tic();
     end
    
    %% Display
    if opts.is_spectrogram_displayed
        subplot(211);
        plot(sounds{1+iteration});
        subplot(212);
        U = U_batches{1+0};
        U1_batches = cell(1, nBatches);
        for batch_index = 0:(nBatches-1)
            U1_batches{1+batch_index} = U_batches{1+batch_index}{1+1}.data;
        end
        U1_batches = cat(2, U1_batches{:});
        for gamma1_index = 1:size(U{1+1}.data, 1)
            U{1+1}.data{gamma1_index} = [U1_batches{gamma1_index, :}];
        end
        scalogram = display_scalogram(sc_unchunk(U(2)));
        imagesc(log1p(scalogram./10.0));
        colormap rev_gray;
        drawnow();
    else
        plot(sounds{1+iteration});
        drawnow();
    end
    
    %% Sonification
    if opts.is_sonified
        soundsc(sounds{1+iteration}, opts.sample_rate);
    end
    
    %% Text generation
    if opts.generate_text
        text = eca_text(S_batches, opts.nLines, opts.sample_rate);
        texts{1+iteration} = text;
    end
    
    %% Clock tick
    iteration = iteration + 1;
end
toc();

sounds{1+0} = [];
sounds(cellfun(@isempty, sounds)) = [];
texts(cellfun(@isempty, texts)) = [];
end

