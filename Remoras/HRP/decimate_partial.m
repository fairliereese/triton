function data = decimate_partial(data, df)

if df > 13
    factors = factor(df);
    
    k = 1;
    while k < length(factors) - 1
        new_fact = factors(k)*factors(k+1);
        
        if new_fact < 13
            if k ~= 1
                factors = [factors(1:k-1), new_fact, factors(k+2:end)];
            else 
                factors = [new_fact, factors(k+2:end)];
            end
        k = k + 1; 
        else
            k = k + 1;
        end
    end
  
    % loop through each sub df and update data
    for k = 1:length(factors)
        data = decimate(data, factors(k));
    end
else
    data = decimate(data, df);
end
end
