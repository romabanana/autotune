function output = psola(win, dpitch, cpitch, fm, outter_overlap)
  l = length(win)/2; %2L window

  output = zeros(1,l+outter_overlap); %inicializa la salida de duracion L.

  output_length = length(output);

  if (cpitch == 0) %Silencio -> f0 = 0;
    return;
  endif
  cpp = round((1/cpitch)* fm); %f0' (hz) -> f0' (samples).

  if (dpitch < 80) % No se puede cantar a menos de 80 hz...
    return;
  else
    dpp = round((1/dpitch)* fm); %f0 (hz) -> f0 (samples).
  endif

  % Detecta el primer pico para centrar las ventanas
  % en estos picos.
  [~, first_peak] = max(win((l/2) +1:(l/2) + 1 +dpp));

  % Define posicion inicial.
  start_pos = (l/2) + first_peak - floor(dpp/2);



  if(start_pos <=0)
    start_pos = l - l/2; %en caso que falle la deteccion de picos.
  endif

  %Extraccion de grains=========================================================

  n = 1; %Numero de periodos en la ventana.
  while(n < output_length/cpp)
    n += 1;
  endwhile

  windows = zeros(n, cpp); %Genera matriz de n ventanas de cpp samples.
  samples = 1; %Lleva cuenta de los samples necesarios para mantener la duracion.
  i = 1;

  while ((samples < output_length+1) )
    start_idx =start_pos+(i-1)*dpp;
    end_idx =start_pos+(i-1)*dpp+cpp-1;
    if(start_idx+cpp>2*l)
      new = windows(i-1,:); %Si se pasa de la ventana, duplica la ultima.
    else
      new = win(start_idx:end_idx);
      %extrae cpp muestras cada dpp.
    endif
    windows(i,:) =  new; %Agrega a la matriz.
    samples += cpp; %Actualiza samples.
    i += 1;
  endwhile



  #Overlap-add==================================================================

  overlap = cpp-dpp; %Overlap necesario para lograr el shift deseado.

  h_win = hanning(cpp)'; %Se suaviza con Hanning windows.
  for(k=1:n)
    windows(k,:) = windows(k,:) .* h_win;
  endfor

  if(cpp>output_length)
    output = win(1,:); %Problemas en frecuencias bajas (<100hz).
    else
    output(1:cpp) += windows(1,:); %Suma la primer Ventana.
  endif

  %Por cada ventana suma y pisa... si overlap>0 -> f0++
  %                                si overlap<0 -> f0--


  for j=2:n
    start_idx =1+cpp*(j-1)-overlap;
    end_idx =1+cpp*(j-1)+cpp-overlap-1;
    if((start_idx)> output_length-cpp+1)
      i = 0;
      k = 0;
      while start_idx<output_length
##        if (k+1>cpp) disp('here');j = j + 1; k = 0; endif;
##        if (j>n) disp('here2');j = j - 1; k = 0; endif;
        output(start_idx) = windows(j,(k+1));
        start_idx = start_idx+i;
        i = i+1;
        k = k +1;
      endwhile
      break;
    endif;

      output(start_idx:end_idx) += windows(j,:);

  endfor
  h_win = hanning(l+outter_overlap)'; %Se suaviza con Hanning windows.
  output = output .* h_win;


endfunction
