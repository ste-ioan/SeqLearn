function A = event_align(data,events,code,range,endcode,nanflag)
%EVENT_ALIGN Align trials in data on appearance of an event code.
%
%  A = event_align(data,events,code,range,endcode,endrange,nanflag)
%
%  Input:
%
%  data--data array, trials in columns.
%  events--event code array, aligned with data
%  code--alignment code
%  range--time range around code.
%  endcode--code after which data should be set to NaN (or zero).  If code
%  is a two element vector, then data is set to NaN (or zero) after the
%  code with the buffer specified in the second element.  If endcode is a 4
%  element vector, then the first pair specifies a pre-data buffer.  To
%  specificy just a start code, use [code buffer NaN NaN].
%  nanflag--pad with NaN's or zeros (1 for NaN, 0 for zeros)
%
%  Output:
%
%  A--array of trials now aligned at a given code.
%
%  If portions of a trial do not extend for the full range about
%  the code, then those portions are represented as NaN's so that
%  measurements can be made with nansum, nanmean, etc. unless the nanflag
%  is set to zero, in which case padding is done with zeros.
%
%  If there is at most one appearance of the code per trial, then A
%  will have the same number of columns as data.  If there is more
%  than one appearance per trial, then A will have as many columns
%  as there are appearances of the code.

%  Fix range
if(length(range)==2)
    range = range(1):range(2);
end
nrange = length(range);

%  Find size of data
[n,ntrials] = size(data);

%  Find position of code in each trial.
%  code_ix is the position in the trial in which the code appears
%  trial_ix are the trials in which the code appears.

[code_ix,trial_ix] = find(events==code);

%  If the code appears at most once per trial, then initialize the
%  new matrix A to have the same number of columns as data and copy
%  data into A.  If the code does not appear in that trial, its
%  column will be (NaN's/zeros) or false depending on the type of data.
%
%  The check on the code count is done by taking a histogram of the trial
%  indices and checking if any appear more than once.
if(all(hist(trial_ix,unique(trial_ix))<=1))
    %  Code appears at most once per trial.
    if(islogical(data))
        A = false(nrange,ntrials);
        Abuff = false;
    elseif(~exist('nanflag','var') || nanflag)
        A = NaN(nrange,ntrials);
        Abuff = NaN;
    else
        A = zeros(nrange,ntrials);
        Abuff = 0;
    end
    %  Copy data into new matrix
    for i=1:length(trial_ix)
        %  First find the range of data around the appearance of the code
        %  that actually is in the trial.  If endcode is defined for this
        %  trial, set start and stop based on the endcode and endrange.
        d_start = max(1,code_ix(i)+range(1));
        d_stop = min(n,code_ix(i)+range(end));
        
        if(exist('endcode','var') && ~isempty(endcode))
            if(length(endcode)==1)
                endcode_ix = find(events(:,trial_ix(i))==endcode);
                d_stop = min([d_stop,endcode_ix]);
            elseif(length(endcode)==2)
                endcode_ix = find(events(:,trial_ix(i))==endcode(1));
                d_stop = min(d_stop,endcode_ix+endcode(2));
            elseif(length(endcode)==4)
                if(~isnan(endcode(1)))
                    startcode_ix = find(events(:,trial_ix(i))==endcode(1));
                    if(startcode_ix+endcode(2) > d_start)
                        data(d_start:startcode_ix+endcode(2),trial_ix(i)) = Abuff;
                    end
                end
                if(~isnan(endcode(3)))
                    endcode_ix = find(events(:,trial_ix(i))==endcode(3));
                    d_stop = min(d_stop,endcode_ix+endcode(4));
                end
            end
        end

        %  Second set the start point of the aligned trial as 1 unless
        %  there was an under-run in the trial itself, and in that case
        %  add a buffer equivalent to the lost portion of the trial.
        A_start = abs(min(0,code_ix(i)+range(1)-1))+1;

        %  Third set the end point of the aligned trial based on the range
        A_stop = A_start+(d_stop-d_start);

        A(A_start:A_stop,trial_ix(i)) = data(d_start:d_stop,trial_ix(i));
    end
else
    %  If the code appears more than once per trial, initialize the
    %  new matrix A to have the same number of columns as there are
    %  appearances of the code and copy data into A.
    A = NaN(nrange,length(trial_ix));

    %  Copy data into new matrix
    for i=1:length(trial_ix)
        
        
        %  First find the range of data around the appearance of the code
        %  that actually is in the trial
        d_start = max(1,code_ix(i)+range(1));
        d_stop = min(n,code_ix(i)+range(end));
        
        if(exist('endcode','var') && ~isempty(endcode))
            if(length(endcode)==1)
                endcode_ix = find(events(:,trial_ix(i))==endcode);
                d_stop = min([d_stop,endcode_ix(i)]);% stempio added (i) here
            else
                error('Encode must be a scalar');
            end
        end
        

        %  Second set the start point of the aligned trial as 1 unless
        %  there was an under-run in the trial itself, and in that case
        %  add a buffer equivalent to the lost portion of the trial.
        A_start = abs(min(0,code_ix(i)+range(1)-1))+1;
        A_stop = A_start+(d_stop-d_start);

        A(A_start:A_stop,i) = data(d_start:d_stop,trial_ix(i));
    end
end
