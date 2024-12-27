% Main script to create the queue and submit work

% Step 1: Create a PollableDataQueue
dq = parallel.pool.PollableDataQueue;

% Step 2: Define the worker function
function workerFunction(dq)
    while true
        % Poll the data queue
        data = poll(dq);
        
        % Exit the loop when no more data is available
        if isempty(data)
            break;
        end
        
        % Process the data
        disp(['Worker received: ', num2str(data)]);
    end
end

% Step 3: Set up the parallel pool
pool = gcp('nocreate');
if isempty(pool)
    pool = parpool;
end

% Step 4: Submit the worker function for execution
f = parfeval(pool, @workerFunction, 0, dq);

% Step 5: Send data to the queue
send(dq, 10);
send(dq, 20);
send(dq, 30);

