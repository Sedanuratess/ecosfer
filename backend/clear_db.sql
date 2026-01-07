-- DİKKAT: Bu komutlar tüm kullanıcı ve tarama verilerini siler!
-- Supabase SQL Editor kısmından bu kodları çalıştırarak tabloları sıfırlayabilirsiniz.

-- 1. Tarama Geçmişini Temizle
TRUNCATE TABLE public.scans CASCADE;

-- 2. Kullanıcı Puanlarını ve İstatistiklerini Sıfırla (Kullanıcıları silmeden sadece puanları sıfırlamak isterseniz)
-- UPDATE public.users SET total_points = 0, total_scans = 0;

-- 3. Tüm Kullanıcıları Silmek İsterseniz (Sıfırdan başlangıç için)
-- Not: Bu işlem auth.users tablosunu etkilemez, sadece public.users tablosunu temizler.
TRUNCATE TABLE public.users CASCADE;
