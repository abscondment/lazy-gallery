import android.app.Activity
import android.content.Context
import android.graphics.Typeface
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

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

import java.util.ArrayList
import java.util.List
import java.util.Map

class LazyGalleryAdapter < BaseAdapter
  def initialize(context:Context):void
    @context = context
    @photos = List(ArrayList.new)
    @oneeighty = int(@context.getResources.getDisplayMetrics.scaledDensity * 180)
  end

  def update_from_json(json:String)
    begin
      data = JSONArray.new json
      data.length.times do |i|
        photo_json = data.getJSONObject(i)
        @photos.add {'caption' => photo_json.getString('caption'), 'src' => photo_json.getString('src')}
      end
    rescue JSONException => e
      Log.e 'LazyGalleryAdapter', 'Could not load JSON', e
    end
    notifyDataSetChanged()
  end

  def getCount
    @photos.size
  end

  def getItem(pos:int):Object
    return @photos.get(pos)
  end

  def getItemId(pos:int):long
    return long(pos)
  end

  def getView(pos:int, convertView:View, parent:ViewGroup)
    layout = RelativeLayout(convertView)
    image = LazyImageView(nil)
    url = String(Map(getItem pos).get('src'))
    
    if layout.nil?
      image = LazyImageView.new(@context, R.drawable.placeholder)
      image.setScaleType(ImageView.ScaleType.FIT_XY)
      image.setLayoutParams Gallery.LayoutParams.new(@oneeighty,@oneeighty)
      image.setBackgroundResource(R.drawable.gallery_background)
      image.setOnClickListener nil
      image.setClickable false
      
      layout = RelativeLayout.new @context
      layout.setLayoutParams Gallery.LayoutParams.new(@oneeighty,@oneeighty)
      layout.setGravity Gravity.CENTER
      layout.addView image
    else
      image = LazyImageView(layout.getChildAt 0)
    end
    
    # show changes
    image.setSrcUrl url
    image.refresh
    
    return View(layout)
  end

end
