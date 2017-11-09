clc
close all
clear all
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
   if (strcmp(words{i}, 'spam') || strcmp(words{i}, 'ham'))
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

alpha = [0.03125, 0.0625, 0.125, 0.25, 0.5, 1];
for al = 1:length(alpha)
for (i=1:length(train_examples))
    for (j=1:length(train_examples(i).words))
        word = train_examples(i).words{j};
        if (train_examples(i).spam == 1)
            numspamwords = numspamwords+1;
            current_count = spamcounts.get(word);
            if (isempty(current_count))
                spamcounts.put(word, 1+alpha(al));    % initialize by including pseudo-count prior
            else
                spamcounts.put(word, current_count+1);  % increment
            end
        else
            numhamwords = numhamwords+1;
            current_count = hamcounts.get(word);
            if (isempty(current_count))
                hamcounts.put(word, 1+alpha(al));    % initialize by including pseudo-count prior
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
spam = 0 ;
for i = 1 : length(train_examples)
    if (train_examples(i).spam == 1)
        spam = spam + 1;
    end
end

ProbIsSpam = spam / length(train_examples);
ProbIsHam = 1 - ProbIsSpam;
Tpositive = 0;
Tnegative = 0;
Fpositive = 0;
Fnegative = 0;

for i = 1 : length(test_examples)
    PSpam = 1;
    PHam = 1;
    for j = 1 : length(test_examples(i).words)
        word = test_examples(i).words{j};
        ProbInSpam = spamcounts.get(word);
        if (isempty (ProbInSpam))
            ProbInSpam = alpha(al);
        end
        ProbInHam = hamcounts.get(word);
        if (isempty (ProbInHam))
            ProbInHam = alpha(al);
        end
        PSpam = PSpam * (ProbInSpam / (numspamwords*alpha(al)*20000));
        PHam = PHam * (ProbInHam / (numhamwords*alpha(al)*20000));
    end
    ProbisSpam = ProbIsSpam * PSpam ; 
    ProbisHam = ProbIsHam * PHam ;
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


accuracy(al) = (Tpositive + Tnegative) * 100 / length(test_examples);
precision = (Tpositive /(Tpositive + Fpositive));
recall = (Tpositive /(Tpositive + Fnegative));
Fscore(al) = ((2 * precision * recall) / (precision + recall));
precision(al) = precision *100;
recall(al) = recall * 100;

 % for training accuracy
Tpositivetr = 0;
Tnegativetr = 0;
Fpositivetr = 0;
Fnegativetr = 0;

for i = 1 : length(train_examples)
    PSpamtr = 1;
    PHamtr = 1;
    for j = 1 : length(train_examples(i).words)
        word = train_examples(i).words{j};
        ProbInSpamtr = spamcounts.get(word);
        if (isempty (ProbInSpamtr))
            ProbInSpamtr = alpha(al);
        end
        ProbInHamtr = hamcounts.get(word);
        if (isempty (ProbInHamtr))
            ProbInHamtr = alpha(al);
        end
        PSpamtr = PSpamtr * (ProbInSpamtr / (numspamwords*alpha(al)*20000));
        PHamtr = PHamtr * (ProbInHamtr / (numhamwords*alpha(al)*20000));
    end
    ProbisSpamtr = ProbIsSpam * PSpamtr ; 
    ProbisHamtr = ProbIsHam * PHamtr ;
    if (ProbisSpamtr >= ProbisHamtr) 
        if (train_examples(i).spam == 1)
            Tpositivetr = Tpositivetr + 1; 
        else
            Fpositivetr = Fpositivetr + 1; 
        end
    else 
        if (train_examples(i).spam == 1)
            Fnegativetr = Fnegativetr + 1; 
        else
            Tnegativetr = Tnegativetr + 1; 
        end
    end
end   

accuracytrain(al) = (Tpositivetr + Tnegativetr) * 100 / length(train_examples);
precisiontrrain = (Tpositivetr /(Tpositivetr + Fpositivetr));
recalltrain = (Tpositivetr /(Tpositivetr + Fnegativetr));
Fscoretrain(al) = ((2 * precisiontrrain * recalltrain) / (precisiontrrain + recalltrain));
precisiontrrain(al) = precisiontrrain *100;
recalltrain(al) = recalltrain * 100;
end

figure
plot(-5:1:0,accuracy,'b');
hold on
plot(-5:1:0,accuracytrain,'r');
xlabel('alpha');
ylabel('Accuracy');
title('Alpha and Accuracy ');

figure
plot(-5:1:0,Fscore,'b');
hold on
plot(-5:1:0,Fscoretrain,'r');
xlabel('alpha');
ylabel('F-score');
title('F-score vs alpha');