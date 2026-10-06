update public.tuition_installments
set due_on = case id
  when 1 then date '2026-08-11'
  when 2 then date '2026-09-15'
  when 3 then date '2026-10-06'
end,
updated_at = now()
where id in (1, 2, 3);
