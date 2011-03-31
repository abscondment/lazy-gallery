import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Drawable
import android.os.Environment
import android.os.Handler
import android.os.Handler.Callback
import android.os.Message
import android.util.Log
import android.widget.ImageView

import java.io.File
import java.io.FileNotFoundException
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

class LazyImageView < ImageView
  implements Callback

  def initialize(context:Context, placeholder:int)
    super context

    @context = context
    @placeholder = placeholder
    @src_url = String(nil)
    @path = String(nil)
    @loaded = false
    @resizing = false
    
    setImageResource @placeholder
  end

  def self.cache_dir(c:Context):File
    @cache_dir ||= File.new(c.getCacheDir, "lazy_image_cache")
    @cache_dir.mkdirs unless @cache_dir.exists
    @cache_dir
  end

  def self.purgeDiskCache(c:Context):void
    thread = Thread.new do
      oldest_acceptable = System.currentTimeMillis
      10.times do
        Log.d 'LazyImageView', 'NOTE: Deleting ALL cached images. Uncomment the next line for a real application.'
      end
      # 8 hours
      # oldest_acceptable = System.currentTimeMillis - long(28800000)
      d = LazyImageView.cache_dir(c)

      files = d.listFiles unless d.nil?
      unless files.nil?
        files.each do |f|
          begin
            # Skip nils, directories, and current files.
            next if f.nil? || (!f.isFile) || f.lastModified >= oldest_acceptable
            Log.v "LazyImageView", "D " + f.getCanonicalPath
            f.delete
          rescue IOException => e
            Log.e "LazyImageView", "purgeDiskCache: Error checking or deleting cache file:", e
          end
        end
      end
    end

    # Do this on a different thread
    LazyGalleryActivity.threadPoolExecutor.execute thread
  end

  def cache_dir:File
    LazyImageView.cache_dir(@context)
  end
  
  # Make this a no-op to keep selected state when updating in the background.
  $Override
  def requestLayout:void
  end
  
  def refresh:void
    unless display_from_path()
      setImageResource @placeholder
    end
  end

  def getPlaceholder
    @placeholder
  end

  def setPlaceholder(placeholder:int)
    @placeholder = placeholder
  end
  
  def setSrcUrl(url:String):void
    @src_url = url
    @path = File.new(cache_dir, "" + @src_url.hashCode + ".jpg").getCanonicalPath
  end

  def getSrcUrl
    @src_url
  end

  def load:void
    unless @loaded || @src_url.nil? || @path.nil?
      AsyncDownload.new(Handler.new(self), @src_url, @path)
    end
  end

  def handleMessage(message:Message)
    result = false

    if (!message.nil?) && message.what == 0
      # Make sure this update is from the current path.
      if @path.equals message.obj
        result = true
        refresh()
      end
    end

    return result
  end
  
  protected
  
  def display_from_path
    d = safe_image_to_drawable(@path, 180)
    
    unless d.nil?
      setImageDrawable(d)
      @loaded = true
    else
      @resizing = false
      @loaded = false
    end
    return @loaded
  end
  
  #
  # Loads a Drawable from the given path, scaling it if it's too large.
  #
  def safe_image_to_drawable(path:String, target_size:int):Drawable
    drawable = Drawable(nil)
    return drawable if path.nil?
    
    begin
      # Short-circuits here if file not found.
      fis = FileInputStream.new(path)
      
      o = BitmapFactory.Options.new      
      # To check on-disk image dimensions without loading pixels.
      o.inJustDecodeBounds = true
      BitmapFactory.decodeStream(fis, nil, o)
      fis.close

      tw = o.outWidth
      th = o.outHeight

      if tw > target_size * 2 && th > target_size * 2
        # Resize is necessary. Do it on another thread.
        unless @resizing
          AsyncResize.new(Handler.new(self), path, target_size)
          @resizing = true
        end
        drawable = Drawable(nil)
      else
        # Size verified - load a drawable.
        drawable = Drawable.createFromPath path
      end
      
    rescue FileNotFoundException => e
      # No file? No problem. It still needs to be downloaded.
    ensure
      fis.close unless fis.nil?
    end

    return drawable
  end

  class AsyncResize
    implements Runnable

    def initialize(handler:Handler, path:String, target_size:int)
      @handler = handler
      @path = path
      @target_size = target_size
      LazyGalleryActivity.threadPoolExecutor.execute self
    end
    
    def run:void
      success = false
      begin
        fis = FileInputStream.new(@path)
        
        o = BitmapFactory.Options.new      
        # To check on-disk image dimensions without loading pixels.
        o.inJustDecodeBounds = true
        BitmapFactory.decodeStream(fis, nil, o)
        fis.close

        tw = o.outWidth
        th = o.outHeight

        # Don't re-resize.
        if tw > @target_size * 2 && th > @target_size * 2        
          scale = 1
          while tw/2 > @target_size && th/2 > @target_size
            tw /= 2
            th /= 2
            scale *= 2
          end
          Log.v "AsyncResize", "Scaling " + o.outWidth + "x" + o.outHeight + " by factor of " + scale + "..."

          fis = FileInputStream.new(@path)
          o = BitmapFactory.Options.new        
          o.inSampleSize = scale
          bitmap = BitmapFactory.decodeStream(fis, nil, o)
          Log.v "AsyncResize", "\tscaled to " + tw + "x" + th
          
          # Write scaled version out
          unless bitmap.nil?
            fos = FileOutputStream.new(@path)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)
            Log.v "AsyncResize", "\tsaved to " + @path
            success = true
          end
        end
      rescue FileNotFoundException => e
        # No file? No problem. It still needs to be downloaded.
      rescue IOException => e
        # TODO
        Log.e "AsyncResize", "Bitmap Resize Failed", e
        # delete path?
      ensure
        fis.close unless fis.nil?
        fos.close unless fos.nil?
        bitmap.recycle unless bitmap.nil?
      end
      
      if success
        @handler.sendMessage(@handler.obtainMessage(0, @path))
      else
        @handler.sendEmptyMessage(1)
      end
    end
  end
end
