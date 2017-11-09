fid = fopen('SMSSpamCollection');            % read file
data = fread(fid);
fclose(fid);
lcase = abs('a'):abs('z');
ucase = abs('A'):abs('Z');
caseDiff = abs('a') - abs('A');
caps = ismember(data,ucase);
data(caps) = data(caps)+caseDiff;     % convert to lowercase
data(data == 9) = abs(' ');          % convert tabs to spaces
validSet = [9 10 abs(' ') lcase];         
data = data(ismember(data,validSet)); % remove non-space, non-tab, non-(a-z) characters
data = char(data);                    % convert from vector to characters

words = strsplit(data');             % split into words

% split into examples
count = 0;
examples = {};

for (i=1:length(words))
   if (strcmp(words{i}, 'spam') || strcmp(words{i},                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            'ham'))
       count = count+1;
       examples(count).spam = strcmp(words{i}, 'spam');
       examples(count).words = [];
   else
       examples(count).words{length(examples(count).words)+1} = words{i};
   end
end

%split into training and test
random_order = randperm(length(examples));
train_examples = examples(random_order(1:floor(length(examples)*.8)));
test_examples = examples(random_order(floor(length(examples)*.8)+1:end));

% count occurences for spam and ham

spamcounts = javaObject('java.util.HashMap');
numspamwords = 0;
hamcounts = javaObject('java.util.HashMap');
numhamwords = 0;

alpha = 0.1;

for (i=1:length(train_examples))
    for (j=1:length(train_examples(i).words))
        word = train_examples(i).words{j};
        if (train_examples(i).spam == 1)
            numspamwords = numspamwords+1;
            current_count = spamcounts.get(word);
            if (isempty(current_count))
                spamcounts.put(word, 1+alpha);    % initialize by including pseudo-count prior
            else
                spamcounts.put(word, current_count+1);  % increment
            end
        else
            numhamwords = numhamwords+1;
            current_count = hamcounts.get(word);
            if (isempty(current_count))
                hamcounts.put(word, 1+alpha);    % initialize by including pseudo-count prior
            else
                hamcounts.put(word, current_count+1);  % increment
            end
        end
    end    
end

% spamcounts.get('free')/(numspamwords+alpha*20000)   % probability of word 'free' given spam
% hamcounts.get('free')/(numhamwords+alpha*20000)   % probability of word 'free' given ham
% will need to check if count is empty!

% For test samples
s = 0 ;
for i = 1 : length(train_examples)
    if (train_examples(i).spam == 1)
        s = s + 1;
    end
end

Spam = s / length(train_examples);
Ham = 1 - Spam;
Tpositive = 0;
Tnegative = 0;
Fpositive = 0;
Fnegative = 0;

for i = 1 : length(test_examples)
    Pspam = 1;
    PHam = 1;
    for j = 1 : length(test_examples(i).words)
        word = test_examples(i).words{j};
        ProbInSpam = spamcounts.get(word);
        if (isempty (ProbInSpam))
            ProbInSpam = alpha;
        end
        ProbInHam = hamcounts.get(word);
        if (isempty (ProbInHam))
            ProbInHam = alpha;
        end
        Pspam = Pspam * (ProbInSpam / (numspamwords*alpha*20000));
        PHam = PHam * (ProbInHam / (numhamwords*alpha*20000));
    end
    ProbisSpam = Spam * Pspam ; 
    ProbisHam = Ham * PHam ;
    if (ProbisSpam >= ProbisHam) 
        if (test_examples(i).spam == 1)
            Tpositive = Tpositive + 1; 
        else
            Fpositive = Fpositive + 1; 
        end
    else 
        if (test_examples(i).spam == 1)
            Fnegative = Fnegative + 1; 
        else
            Tnegative = Tnegative + 1; 
        end
    end
end   

% final calculations
accuracy = (Tpositive + Tnegative) * 100 / length(test_examples)
precision = (Tpositive /(Tpositive + Fpositive));
recall = (Tpositive /(Tpositive + Fnegative));
F_score = ((2 * precision * recall) / (precision + recall))
precision = precision *100
recall = recall * 100
c_matrix = [Tpositive Fpositive ; Fnegative Tnegative]