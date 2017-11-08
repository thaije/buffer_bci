run ../../utilities/initPaths
% load the list of data-sets we want to analyse
datasets_offline();
dataRootDir = '~/data/bci'; % main directory the data is saved relative to in sub-dirs
trlen_ms=750;
label   ='movement'; % generic label for this slice/analysis type
makePlots=1; % flag if we should make summary ERP/AUC plots whilst slicing

% get the set of algorithms to run
algorithms_brainfly();
% list of default arguments to always use
% N.B. Basicially this is a standard ERSP analysis setup
default_args={,'badtrrm',0,'badchrm',0,'detrend',2,'spatialfilter','none','freqband',[6 8 80 90],'width_ms',250,'aveType','abs'};

% summary results storage.  Format is 2-d cell array.  
% Each row is an algorithm run with 4 columns: {subj session algorithm_label performance}
resultsfn=fullfile(dataRootDir,expt,sprintf('analyse_res'));
try % load the previously saved results if possible..
   if ( ~exist('results','var') ) 
      load(resultsfn);
   end
catch
   results=cell(0,4);
end

% run the given analysis
for si=1:numel(datasets);
  subj   =datasets{si}{1};
  for sessi=1:numel(datasets{si})-1;
     session=datasets{si}{1+sessi};
     saveDir=session;
     if(~isempty(stripFrom))
        tmp=strfind(session,stripFrom);
        if ( ~isempty(tmp) ) saveDir=session(1:tmp-1);  end
     end

     % load the sliced data
     dname = fullfile(dataRootDir,expt,subj,saveDir,sprintf('%s_%s_sliced',subj,label));
     if( ~(exist(dname,'file') || exist([dname '.mat'],'file')) )
        warning('Couldnt find sliced data for : %s.  skipping',dname);
        continue;
     end
     fprintf('Loading: %s\n',dname);
     load(dname);
     fprintf('Loaded %d events',numel(devents));
     if ( numel(devents)==0 ) continue; end;

     % run the set of algorithms to test
     for ai=1:numel(algorithms)
        alg=algorithms{ai}{1};

        % check if already been run
        mi=strcmp(subj,results(:,1)) &strcmp(saveDir,results(:,2)) &strcmp(alg,results(:,3));
        if( any(mi) ) 
           fprintf('Skipping prev run analysis: %s\n',alg);
        end

        fprintf('Trying: %s %s\n',subj,alg);
        try; % run in catch so 1 bad alg doesn't stop everything

           [clsfr,res]=buffer_train_ersp_clsfr(data,devents,hdr,default_args{:},algorithms{ai}{2:end},'visualize',0);
           % save the summary results
           results(end+1,:)={subj saveDir alg res.opt.tst};
           fprintf('%d) %s %s %s = %f\n',ai,results{end,:});

        catch;
           err=lasterror, err.stack(1)
           fprintf('Error in : %d=%s,    IGNORED\n',ai,alg);
        end

     end

     % save the updated summary results
     save(resultsfn,'results');    
  end % sessions
end % subjects
% show the final results set
[results,si]=sort(results,'rows'); % canonical order... subj, session, alg
results