drop policy if exists "Open chat participants can send messages" on public.study_help_messages;
create policy "Open chat participants can send messages"
  on public.study_help_messages for insert to authenticated with check (
    sender_id = auth.uid()
    and message_kind in ('text', 'image')
    and exists (
      select 1 from public.study_help_chats c where c.id = chat_id and (
        (c.author_id = auth.uid() and c.author_closed_at is null)
        or (c.responder_id = auth.uid() and c.responder_closed_at is null)
      )
    )
    and (attachment_path is null or split_part(attachment_path, '/', 1) = auth.uid()::text)
  );
create policy "Users can delete their own study help media"
  on storage.objects for delete to authenticated
  using (bucket_id = 'study-help-media' and (storage.foldername(name))[1] = auth.uid()::text);
