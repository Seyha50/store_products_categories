<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    protected $primaryKey = 'ProductID';
    public $timestamps = false;           // table មិនមាន created_at/updated_at
    protected $fillable = [
        'ProductName','Description','CategoryID','Barcode','Expiredate',
        'Qty','UnitPriceIn','UnitPriceOut','ProductImage','isDeleted'
    ];
    protected $casts = ['isDeleted' => 'boolean'];
    protected $appends = ['image_url'];

    public function category() {
        return $this->belongsTo(Category::class, 'CategoryID', 'category_id');
    }

    public function getImageUrlAttribute() {
        return $this->ProductImage ? asset('storage/'.$this->ProductImage) : null;
    }
}
