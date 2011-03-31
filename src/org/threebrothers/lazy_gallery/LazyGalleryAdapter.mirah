import android.app.Activity
import android.content.Context
import android.graphics.Typeface
import android.location.Location
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.Gallery
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import android.widget.AdapterView
import android.widget.AdapterView.OnItemSelectedListener

import java.util.ArrayList
import java.util.List
import java.util.Locale
import java.util.Map

class LazyGalleryAdapter < BaseAdapter
  def initialize(context:Context, container:View):void
    @context = context
    @container = container
    @photos = List(ArrayList.new)
  end

  def getCount
    s = @photos.size
    (s == 0) ? s : s + 1
  end

  def getItem(pos:int):Object
    if pos > 0
      return @photos.get(pos - 1)
    else
      return nil
    end
  end

  def getItemId(pos:int):long
    return long(pos)
  end

  def getView(pos:int, convertView:View, parent:ViewGroup)
    layout = RelativeLayout(convertView)
    image = LazyImageView(nil)
    update_view = false

    unless layout.nil?
      image = LazyImageView(layout.getChildAt 0)
    end
    
    # Images
    text = TextView(nil)

    url = String(Map(getItem pos).get('src'))

    if image.nil?
      image = LazyImageView.new(@context, R.drawable.placeholder)
      update_view = true
    elsif image.getPlaceholder != R.drawable.placeholder
      image.setPlaceholder R.drawable.placeholder
      update_view = true
    end

    if update_view
      image.setScaleType(ImageView.ScaleType.FIT_XY)
      image.setLayoutParams Gallery.LayoutParams.new(180,180)
      image.setBackgroundResource(R.drawable.gallery_background)
      image.setOnClickListener nil
      image.setClickable false
    end

    loc = Location(Map(getItem pos).get('loc'))
    image.setSrcUrl url
    
    if layout.nil?
      layout = RelativeLayout.new @context
      layout.setLayoutParams Gallery.LayoutParams.new(pos == 0 ? 64 : 180,180)
      layout.setGravity Gravity.CENTER
      rlp = RelativeLayout.LayoutParams.new(ViewGroup.LayoutParams.WRAP_CONTENT,
                                            ViewGroup.LayoutParams.WRAP_CONTENT)
      rlp.setMargins(10,5,10,5)
      rlp.addRule(RelativeLayout.ALIGN_PARENT_RIGHT)
      rlp.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
      layout.addView image
    elsif update_view
      layout.setLayoutParams Gallery.LayoutParams.new(pos == 0 ? 64 : 180,180)      
    end
    
    # show changes
    image.refresh
    
    return View(layout)
  end

  def getOnItemSelectedListener(textView:TextView)
    SelectionListener.new(self, textView)
  end
end

class SelectionListener
  implements OnItemSelectedListener

  def initialize(adapter:LazyGalleryAdapter, textView:TextView)
    @adapter = adapter
    @textView = textView
  end
  
  def onItemSelected(parent:AdapterView, view:View, pos:int, id:long)
    if pos == 0
      Gallery(parent).setSelection(1)
      return
    else
      view.setSelected true
    end
    
    # Preload children of the Gallery (i.e. those elements that are visible)
    unless parent.nil?
      parent.getChildCount.times do |i|
        v = RelativeLayout(parent.getChildAt(i))
        unless v.nil? || v.getChildCount < 1
          LazyImageView(v.getChildAt 0).load
        end
      end
    end

    unless @textView.nil?
      photo_map = Map(@adapter.getItem pos)
      if photo_map.containsKey('caption')
        @textView.setText String(photo_map.get('caption'))
        @textView.setVisibility View.VISIBLE
      else
        @textView.setVisibility View.INVISIBLE
      end
    end
  end

  def onNothingSelected(parent:AdapterView)
    unless @textView.nil?
      @textView.setVisibility View.INVISIBLE
      @textView.setText ''
    end
  end
end
