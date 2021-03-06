function [S, U, Y] = sc_propagate(signal, archs)

is_chunked = archs{1}.banks{1}.behavior.is_chunked;
is_unchunked = archs{1}.banks{1}.behavior.is_unchunked;
is_minibatch = ...
    (nargout == 1) && ...
    is_chunked && ...
    (archs{1}.banks{1}.behavior.max_minibatch_size < Inf);

U0 = initialize_U(signal, archs{1}.banks{1});
if is_minibatch
    if archs{1}.etc.is_waitbar_shown
        f = waitbar(0, 'Chunking ...');
        if archs{1}.etc.is_waitbar_docked
            set(f, 'WindowStyle', 'docked');
        end
        drawnow();
        cumulative_time = 0;
    end
    nChunks = size(U0.data, 2);
    max_minibatch_size = archs{1}.banks{1}.behavior.max_minibatch_size;
    nBatches = ceil(nChunks / max_minibatch_size);
    U0_batches = cell(1, nBatches);
    for batch_id = 1:nBatches
        U0_batch = U0;
        chunk_start = 1 + (batch_id-1) * max_minibatch_size;
        chunk_stop = min(nChunks, chunk_start + max_minibatch_size - 1);
        U0_batch.data = U0.data(:, chunk_start:chunk_stop, :);
        %U0_batch.ranges{1}(1,2) = chunk_start;
        %U0_batch.ranges{1}(3,2) = chunk_stop;
        U0_batches{batch_id} = U0_batch;
    end
    S_batches = cell(1, nBatches);
else
    nBatches = 1;
end


% Loop over mini-batches.
nLayers = length(archs);
for batch_id = 1:nBatches
    % Initialization of networks S, U, and Y.
    % S and U are zero-based ; Y is one-based.
    S = cell(1, nLayers);
    U = cell(1, nLayers);
    Y = cell(1, nLayers);

    if is_minibatch
        U{1+0} = U0_batches{batch_id};
        if archs{1}.etc.is_waitbar_shown
            tic();
        end
    else
        U{1+0} = U0;
    end

    % Propagation cascade
    for layer = 1:nLayers
        arch = archs{layer};
        previous_layer = layer - 1;
        % Scatter iteratively layer U to get sub-layers Y
        if isfield(arch, 'banks')
            Y{layer} = U_to_Y(U{1+previous_layer}, arch.banks);
        else
            Y{layer} = U(1+previous_layer);
        end

        % Apply nonlinearity to last sub-layer Y to get layer U
        if isfield(arch, 'nonlinearity')
            U{1+layer} = Y_to_U(Y{layer}{end}, arch.nonlinearity);
        end

        % Blur/pool first layer Y to get layer S
        if isfield(arch, 'invariants')
            S{1+previous_layer} = Y_to_S(Y{layer}, arch);
        end
    end

    if is_minibatch
        S_batches{batch_id} = S;
        if archs{1}.etc.is_waitbar_shown
            iteration_time = toc();
            cumulative_time = cumulative_time + iteration_time;
            cumulative_time_str = datestr(datetime( ...
                0,0,0,0,0, cumulative_time), 'HH:MM:SS');
            remaining_time = (nBatches-batch_id) * iteration_time;
            remaining_time_str = datestr(datetime( ...
                0,0,0,0,0, remaining_time), 'HH:MM:SS');
            waitbar(batch_id/nBatches, f, ...
                ['Scattering. ', ...
                 'Elapsed time: ', cumulative_time_str, '. ', ...
                 'Remaining time: ', remaining_time_str, '.']);
            tic();
        end
    elseif is_unchunked
        S = sc_unchunk(S);
    end

end

if is_minibatch
    if is_unchunked
        if archs{1}.etc.is_waitbar_shown
            waitbar(1, f, 'Unchunking ...');
        end
        S = reduce_minibatch(S_batches);
        S = sc_unchunk(S);
    else
        S = cat(1, S_batches{:});
    end
    if archs{1}.etc.is_waitbar_shown
        close(f);
    end
end

end
