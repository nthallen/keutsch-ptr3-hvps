%%
ranges = [200,400,800,2000,3000]';
hi_thresh = (32768/6.144)*40.*(5./ranges);
lo_thresh = (32768/6.144)*35.*(5./ranges);
for i=1:length(ranges)
  fprintf(1,'Range: %4d V Hi: %04X Lo: %04X\n', ...
    ranges(i), floor(hi_thresh(i)), floor(lo_thresh(i)));
end
